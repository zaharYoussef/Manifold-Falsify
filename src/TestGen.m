classdef TestGen < handle
    properties
        br
        phi
        
        params
        lb
        rb
        tspan
        
        net_name
        net
        nn_input
        nn_input_num
        nn_tspan_num
        nn_num_neurons
        
        
        cov_curr
        act_curr
        
        budget
        budget_local
        
        qseed_size
        qseed
        
        
        solver
        solver_options
        
        objective
        obj_best
        x_best
        
        num_sim
        num_sim2
        time_cost
        
        falsified
    end
    
    methods
        
        function this = TestGen(br, phi, nn_in, qs_size, solver, budget, budget_local)
            this.br = br;
            
            this.phi = phi;
            this.budget =  budget;
            this.budget_local = budget_local;
            
            this.tspan = br.Sys.tspan;
            
            this.params = br.GetSysVariables();
            rgs = br.GetParamRanges(this.params);
            this.lb = rgs(:, 1);
            this.rb = rgs(:, 2);
            
            % this.net_name = nn;
            % load(nn, 'net');
            % this.net = net;
            this.nn_input = nn_in;
            this.nn_input_num = numel(nn_in);
            this.nn_tspan_num = numel(this.tspan);
            % this.nn_num_neurons = 0;
            % for i = 1: this.net.numLayers - 1
            %     this.nn_num_neurons = this.nn_num_neurons + this.net.layers{i}.dimensions;
            % end
            
            this.cov_curr = 0;
            % this.act_curr = cell(1, this.net.numLayers-1);
            % for a = 1:numel(this.act_curr)
            %     this.act_curr{a} = zeros(this.net.layers{a}.dimensions, 1);
            % end
            
            this.qseed_size = qs_size;
			this.qseed = CQueue();
            this.init_seed();
                        
            %initializing python class to setup coverage
            GetManifoldCov.initializePythonObject();
            
            this.solver = solver;
            this.setup_cmaes();
            
            
            this.objective = @(x)(objective_wrapper(this, x));
            
            this.obj_best = intmax;
            this.x_best = [];
            this.num_sim = 0;
            this.num_sim2 = 0;
            this.time_cost = 0;
            
            this.falsified = 0;
            
            rng('default');
            rng(round(rem(now, 1)*1000000));
        end
        
        function run(this)
            tic;
            while true
                if this.qseed.isempty()
                    this.init_seed();
                end
                u = this.qseed.pop();
                
                this.solver_options.StopIter = this.budget_local;
                [~, fval, counteval, stopflag, out, bestever] = cmaes(this.objective, u, [], this.solver_options);
                
                this.obj_best = bestever.f;
                this.x_best = bestever.x;
                this.num_sim = this.num_sim + counteval;
                
                this.num_sim2
                time = toc;
                this.time_cost = time;
                
                if this.obj_best < 0
                    this.falsified = 1;
					this.x_best
                    break;
                end
                
			    if this.istimeout()
                    break;
                end
            end
        end
        
        function init_seed(this)            
            for j = 1:this.qseed_size
                x0 = [];
                lb__ = this.lb;
                ub__ = this.rb;
                num = numel(lb__);
                for i = 1: num
                    is__ = lb__(i) + rand()*(ub__(i) - lb__(i));
                    x0 = [x0 is__];
                end
                this.qseed.push(x0');
            end
        end
        
		function yes = istimeout(this)
			yes = (this.num_sim2 > this.budget);
		end

        function fval = objective_wrapper(this, x)
           time = toc;
           if this.obj_best < 0 || this.istimeout()
               fval = this.obj_best;
           else
               fval = this.obtain_robustness(x);
               
               this.num_sim2 = this.num_sim2 + 1;
               
               % maybe not work; 
               if fval < this.obj_best 
                   this.obj_best = fval;
                   this.x_best = x;
               end
                   
           end
        end
        
        function rob = obtain_robustness(this, x)
            this.br.SetParam(this.br.GetSysVariables(), x); 
            this.br.Sim(this.tspan);
            rob = this.br.CheckSpec(this.phi);
            
            % make sure that in simulink, the corres. signal is output
            signal_list = this.br.GetSignalList();
            
            signals_origin = this.br.P.traj{1,1}.X;
            signal_indices = cellfun(@(signal) find(strcmp(signal, signal_list)), signal_list);

            % Identify the index for v_lead signal
            v_lead_index = find(strcmp('v_lead', signal_list));
            % Extract all values for v_lead across all iterations into an array
            v_lead = signals_origin(v_lead_index, :); 

            [temp_cov] = this.coverage(v_lead);
            fprintf('this.cov_curr value: %f\n ', this.cov_curr)
            fprintf('temp_cov value: %f\n', temp_cov)
            if temp_cov > this.cov_curr
                this.cov_curr = temp_cov;
                this.qseed.push(x);
            end
            
        end

        function [temp_cov] = coverage(this, data)
            temp_cov = GetManifoldCov.processData(data);
        end


        
        
        function setup_cmaes(this)
            this.solver_options = cmaes();
            this.solver_options.LBounds = this.lb;
            this.solver_options.UBounds = this.rb;
        end
    end
    
end
