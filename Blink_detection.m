%% Main file for blink detection.
% Code for blink detection using threshold algorithm.
% Two modes for detection: manual, automatic.
% If automatic is set to true: 
%   Threshold value is automatically determined: 
%   A 1-second baseline is obtained from the second before the first
%   intensification. Std is calculated for this baseline. Threshold value
%   is this std multiplied by a constant (n_stds) -> th=n_stds*std(baseline)
% If automatic is set to false:
%   thresold values stored in th_levels are used.
%
% Code for the paper: 
% Laport, F., Iglesia, D., Dapena, A., Castro, P. M., & Vazquez-Araujo, F. J. (2021). 
% Proposals and comparisons from one-sensor EEG and EOG human-machine interfaces. Sensors, 21(6), 2220.
clear;
close all;

%% VARIABLES.
fs = 250;
epoch_time = 1;
epoch_length = epoch_time * fs;
time = 0:1/fs:epoch_length*(1/fs)-1/fs;
ch = 1;
subjects = {'s1', 's2', 's3', 's4', 's5', 's6', 's7', 's8', 's9'};

% Execution variables.
automatic = true;
n_stds = 4;
paradigm = 'RC';
th_levels = [50, 50, 50, 200, 40];
plot_figures = 0;


for subject = 1:length(subjects)
    % LOAD DATA.
    files = get_files(subjects{subject}, paradigm, 'Blink');
    
    acc = zeros(length(files), 1);
    for file = 1:length(files)
        % Read the EEG and stimuli data.
        [data, stim_codes, stim_target(:, file)] = read_data(subjects{subject}, files{file}, paradigm);
        
        % Load the triggers for the stimuli.
        analog_data = data(:, 10);
        [~, peaks] = findpeaks(analog_data, 'MinPeakDistance', 0.5*250, 'MinPeakHeight', 600);
        
        
        %% FILTER THE DATA.
        bpFilt = designfilt('bandpassiir','FilterOrder', 4, ...
            'HalfPowerFrequency1', 1 ,'HalfPowerFrequency2', 10, ...
            'SampleRate',fs, 'DesignMethod', 'butter');
        %     fvtool(bpFilt);
        
        bsFilt = designfilt('bandstopiir','FilterOrder',20, ...
            'HalfPowerFrequency1', 20,'HalfPowerFrequency2',60, ...
            'SampleRate',fs);
        
        data = filter(bpFilt, data(:,1:8));
        
        if plot_figures 
            time = 0:1/fs:size(data,1)*(1/fs)-1/fs;
            figure;
            plot(time, data(1:end,1), 'LineWidth', 1); hold on;
            xlim([5,38]);
            xlabel('Time (s)');
            ylabel('Amplitude (\muV)', 'interpreter', 'tex');
            set(gca,'FontName','Times New Roman','FontSize',12,'YGrid', 'on');
        end
        
        %% EXTRACT EPOCHS.
        % Get all stimuli > 100, since they represent the image codes.
        stimuli = stim_codes(stim_codes(:, 1) > 100, :);
        
        % Check if the detected peaks is equal to the number of stimuli.
        if length(peaks) ~= size(stimuli, 1)
            error('WARNING: Peaks and stimuli does not match!');
        end
        
        %     plot([peaks'; peaks'], repmat(ylim', 1, size(peaks,1)))
        
        
        if automatic == true
            baseline = data(peaks(1)-fs:peaks(1)-1, ch);
            th = n_stds*std(baseline);
        else
            th = th_levels(subject);
        end
        
        [stim_count, stim_sum, epochs] = extract_epochs(data, stim_codes, peaks, epoch_length, ch);
        stim_array(:,:,:, file) = epochs;
        
        blink_count = zeros(size(stim_count));
        for stim = 1:size(epochs, 3)
            for trial = 1:stim_count(stim)
                is_blink = detect_blinks(epochs(:, trial, stim), th);
                blink_count(stim) = blink_count(stim) + is_blink;
                blink_stim(stim, trial, file) = is_blink;
            end
        end
        
        n_trials = max(stim_count);
        
        if size(stim_target, 1) > 1
            row = find(blink_count(1:3) == n_trials);
            col = find(blink_count(4:6) == n_trials);
            if length(row) == 1 && length(col) == 1
                acc(file) = sum(row == stim_target(1, file) - 100 & col == stim_target(2, file)-100-3);
            end
        else
            tg = find(blink_count == n_trials);
            if length(tg) == 1
                acc(file) = sum(tg == stim_target(file)- 100);
            end
        end
    end % files.
    
    fprintf('Acc TH: %d \t -> \t %s [%s] \n', sum(acc)/length(files) * 100, subjects{subject}, paradigm);
end



