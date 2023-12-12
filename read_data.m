function [data, stim_codes, stim_target] = read_data(subject, data_path, paradigm)
    % Reads the recorded data accordinf to file name = data_path and the
    % subject.
    
    % Data paths. 
    data_file_name = ['FinalRecordings/' subject '/' data_path '/Raw-EEG_' data_path '.csv'];
    stims_file_name = ['FinalRecordings/' subject '/' data_path '/Raw-STIMS_' data_path '.csv'];
    info_file_name = ['FinalRecordings/' subject '/' data_path '/ExpInfo_' data_path '.csv'];
        
    % Read CSV files.
    data = csvread(data_file_name, 1, 1);
    stim_codes = csvread(stims_file_name, 1, 1);
    info = readtable(info_file_name);
    
    % Determine the code of target stimuñus according to the paradigm.
    if strcmpi(info{1, {'TARGET'}}, 'heater')
        if strcmp(paradigm, 'RC')
            stim_target = [102, 106];
        else
            stim_target = 106;
        end
    else
        if strcmp(paradigm, 'RC')
            stim_target = [101, 105];
        else
            stim_target = 102;
        end
    end
end