classdef GetManifoldCov
    methods (Static)
        function initializePythonObject()
            % Define initialization parameters
            exp_dir = 'exps/acc/8d-8d-new/'; 
            dataset = 'acc'; % Example: 'mnist'
            v = 2;
            t = 2;

            initParams = table({exp_dir}, {dataset}, v, t, ...
                'VariableNames', {'exp_dir', 'dataset', 'v', 't'});
            initParamsCsvPath = '/home/zahar022/Manifold-Falsify/src/cov/comFiles/init_params.csv';
            writetable(initParams, initParamsCsvPath);
            disp('Initialization parameters written to CSV.');

            flagFilePath = '/home/zahar022/Manifold-Falsify/src/cov/comFiles/init_flag.txt';
            GetManifoldCov.writeFlag(flagFilePath, 'init');
            disp('Initialization request sent to Python.');
            GetManifoldCov.waitForFlag(flagFilePath, 'init-done');
            disp('Initialization signal acknowledged by Python.');
        end

        function [coverage] = processData(data)
            dataFlagPath = '/home/zahar022/Manifold-Falsify/src/cov/comFiles/data_flag.txt';
            matlabToPythonCsvPath = '/home/zahar022/Manifold-Falsify/src/cov/comFiles/data_to_encoder.csv';
            pythonToMatlabCsvPath = '/home/zahar022/Manifold-Falsify/src/cov/comFiles/coverage_from_encoder.csv';
        
            data_table = table(data', 'VariableNames', {'v_lead'});
            writetable(data_table, matlabToPythonCsvPath);
            disp('Data written to MATLAB-to-Python CSV.');
        
            GetManifoldCov.writeFlag(dataFlagPath, 'new data');
            disp('Waiting for Python to process the new data...');
            GetManifoldCov.waitForFlag(dataFlagPath, 'data-processed');
        
            processedData = readtable(pythonToMatlabCsvPath);
            disp('Processed data received from Python:');
            coverage = processedData.current_coverage;
            fprintf('current coverage in GetManifold: %f\n', coverage);
            fID = fopen(pythonToMatlabCsvPath, 'w');
            fclose(fID);
        end

        function writeFlag(filePath, message)
            fileID = fopen(filePath, 'w');
            fprintf(fileID, '%s', message);
            fclose(fileID);
        end

        function waitForFlag(filePath, expectedMessage)
            while true
                if exist(filePath, 'file')
                    fileID = fopen(filePath, 'r');
                    flagContent = fscanf(fileID, '%s');
                    fclose(fileID);
                    if strcmp(flagContent, expectedMessage)
                        break;
                    end
                end
                pause(1);
            end
        end
    end
end

