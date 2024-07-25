import sys

# Configuration settings
model = []
input_name = []
input_range = []
parameters = []
timespan = ''
trials = ''
timeout = ''
addpath = []
nn_in = []

status = 0
arg = ''
linenum = 0

# Read configuration file
with open(sys.argv[1], 'r') as conf:
    for line in conf.readlines():
        argu = line.strip().split()
        if not argu:  # Skip empty lines
            continue
        if status == 0:
            if len(argu) < 2:
                continue
            arg = argu[0]
            linenum = int(argu[1])
            status = 1
        elif status == 1:
            if arg == 'model':
                model = argu  # Assume only one model configuration line
            elif arg == 'addpath':
                addpath.extend(argu)
            elif arg == 'input_name':
                input_name.extend(argu)
            elif arg == 'input_range':
                input_range.append([float(x) for x in argu])
            elif arg == 'parameters':
                parameters.append(' '.join(argu))
            elif arg == 'timespan':
                timespan = ' '.join(argu)
            elif arg == 'trials':
                trials = ' '.join(argu)
            elif arg == 'timeout':
                timeout = ' '.join(argu)
            elif arg == 'nn_in':
                nn_in.extend(argu)

            linenum -= 1
            if linenum == 0:
                status = 0

# Generate the script for the single model specified
filename = f'benchmarks/{model[0]}_script.sh'  # Use model[0] to dynamically name the file
with open(filename, 'w') as bm:
    bm.write('#!/bin/sh\n')
    bm.write('csv=$1\n')
    bm.write('matlab -nodesktop -nosplash <<EOF\n')
    bm.write('clear;\n')
    for path in addpath:
        bm.write(f'addpath(genpath(\'{path}\'));\n')
    bm.write('InitBreach;\n\n')
    bm.write('\n'.join(parameters) + '\n')
    bm.write(f'mdl = \'{model[0]}\';\n')
    bm.write('Br = BreachSimulinkSystem(mdl);\n')
    bm.write('br = Br.copy();\n')
    bm.write('controlpoints = 10;\n')
    bm.write(f'br.Sys.tspan = {timespan};\n')
    bm.write('input_gen.type = \'UniStep\';\n')
    bm.write('input_gen.cp = 10;\n')  # Assuming control points are 10
    bm.write('br.SetInputGen(input_gen);\n')
    input_names_formatted = ", ".join("'" + name + "'" for name in input_name)
    bm.write('input_name = {' + input_names_formatted + '};\n')
    input_ranges_formatted = ', '.join('[' + ' '.join(map(str, rng)) + ']' for rng in input_range)
    bm.write('input_range = [' + input_ranges_formatted + '];\n')
    bm.write('spec = \'alw_[0,50](d_rel[t] - 1.4 * v_ego[t] >= 4)\';\n')
    bm.write('phi = STL_Formula(\'phi\', spec);\n')
    bm.write(f'filename = \'{model[0]}_results\';\n')
    bm.write('for cpi = 0:controlpoints -1\n')
    bm.write('\tfor ini = 0:numel(input_name) - 1\n')
    bm.write('\t\tin = input_name(ini + 1);\n')
    bm.write('\t\tbr.SetParamRanges({strcat(in, \'_u\', num2str(cpi))}, input_range(ini + 1, :));\n')
    bm.write('\tend\n')
    bm.write('end\n')
    bm.write(f'qs_size = 5;\n')
    nn_in_formatted = ", ".join("'" + n + "'" for n in nn_in)
    bm.write(f'nn_in = {{{nn_in_formatted}}};\n')
    bm.write("solver = 'cmaes';\n")
    bm.write(f'trials = {trials};\n')
    bm.write(f'budget_t = {timeout};\n')
    bm.write('budget_local = 2;\n')
    bm.write('falsified = [];\n')
    bm.write('coverage = [];\n')
    bm.write('obj_bests = [];\n')
    bm.write('time = [];\n')
    bm.write('num_sim = [];\n')
    bm.write('num_sim2 = [];\n')
    bm.write('for n = 1:trials\n')
    bm.write('\ttg = TestGen(br, phi, nn_in, qs_size, solver, budget_t, budget_local);\n')
    bm.write('\ttg.run();\n')
    bm.write('\tfalsified = [falsified; tg.falsified];\n')
    bm.write('\tcoverage = [coverage; tg.cov_curr];\n')
    bm.write('\tobj_bests = [obj_bests; tg.obj_best];\n')
    bm.write('\ttime = [time; tg.time_cost];\n')
    bm.write('\tnum_sim2 = [num_sim2; tg.num_sim2];\n')
    bm.write('end\n')
    bm.write('budget_locals = ones(trials, 1)*budget_local;\n')
    bm.write(f'specs = {{{"; ".join("spec" for _ in range(int(trials)))}}};\n')
    bm.write(f'filenames = {{{"; ".join("filename" for _ in range(int(trials)))}}};\n')
    bm.write('result = table(filenames, specs, budget_locals, falsified, time, num_sim2, coverage, obj_bests);\n')
    bm.write('writetable(result,\'$csv\',\'Delimiter\',\';\');\n')
    bm.write('quit force\n')
    bm.write('EOF\n')
