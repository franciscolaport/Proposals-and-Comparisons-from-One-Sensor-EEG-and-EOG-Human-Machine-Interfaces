%% Main file for P300 detection. 
% Two modes for detection: manual, automatic.
% if variable 'automatic' = true -> P300 window is automatically calculated
% for each subject. Otherwise, atuomatic = false, the P300 window takes the
% values stored in the variable p300_wins.
%
% Code for the paper: 
% Laport, F., Iglesia, D., Dapena, A., Castro, P. M., & Vazquez-Araujo, F. J. (2021). 
% Proposals and comparisons from one-sensor EEG and EOG human-machine interfaces. Sensors, 21(6), 2220.

clear;
close all;


%% VARIABLES.
% Common variables.
fs = 250;
epoch_time = 0.6;
epoch_length = epoch_time * fs;
time = 0:1/fs:epoch_length*(1/fs)-1/fs;
ch = 1;


p300_wins_1by1 = [[300, 400]; [300, 400]; [300, 400]; [350, 450]; [350, 450]; [250, 400]; [200 300]; [200 300]; [300 400]];
p300_wins_rc = [[300, 400]; [250, 350]; [300, 400]; [350, 450]; [350, 450]; [250, 400]; [150 250]; [200 300]; [250 400]];

subjects = {'s1', 's2', 's3', 's4', 's5', 's6', 's7', 's8', 's9'};
% p300_wins_rc = [150, 250];
% subjects = {'Yago'};

% Execution variables.
paradigm = 'RC';        % stimulation paradigm. [RC or 1by1].
automatic = true;      % if true the p300 window is automatically calculated.
step_by_step = 0;
plot_figs = 0;
save_res = 0;

if automatic == false
    if strcmp(paradigm, '1by1')
        p300_wins = p300_wins_1by1;
    elseif strcmp(paradigm, 'RC')
        p300_wins = p300_wins_rc;
    end
end


%% CODE.
for subject = 1:length(subjects)
    
    % LOAD DATA.
    files = get_files(subjects{subject}, paradigm, 'P300');
    
    % Accuracy.
    acc = zeros(0,0);
    
    for file = 1:length(files)
        % Read the EEG and stimuli data.
        [data, stim_codes, stim_target(:, file)] = read_data(subjects{subject}, files{file}, paradigm);

        % Obtain trigger data for the stimuli.
        analog_data = data(:, 10);
        [~, peaks] = findpeaks(analog_data, 'MinPeakDistance', 0.1*250, 'MinPeakHeight', 600);
        
        % Filter the data.
        bpFilt = designfilt('bandpassiir','FilterOrder', 20, ...
            'HalfPowerFrequency1', 1 ,'HalfPowerFrequency2', 15, ...
            'SampleRate',fs, 'DesignMethod','butter');
        
        data = filter(bpFilt, data(:,1:8));
         
        %Extract the epochs.
        [stim_count, stim_sum, epochs] = extract_epochs(data, stim_codes, peaks, epoch_length, ch);
        stim_array(:,:,:, file) = epochs(:,1:50,:);

        % Average the trials according to its stimulus. Blocks of 5 by 5
        % instensifications. Ranging form 5 to 50.
        step = 5;
        intensifications = step:step:50;
        
        for cur_inten = intensifications
            cur_epochs = stim_array(:, 1:cur_inten, :, file);
            cur_avg = squeeze(mean(cur_epochs, 2));
            
            if automatic == true
                [area, p300_peaks, n400_peaks, pp_diff] = find_p300_peak(cur_avg, fs);
            else
                [area, p300_peaks, n400_peaks, pp_diff] = find_p300_peak(cur_avg, fs, p300_wins(subject, :));
            end
            
            acc(cur_inten/step, file) = threshold_detection_p300(area, stim_target(:, file));
            
            avg(:,:,cur_inten/step, file) = cur_avg;
        end
  
    end % files.
    
    % Threhold Accuracy.
    acc_tot = sum(acc, 2)/length(files);
    fprintf('Acc TH: %f  \t -> \t %s [%s] \n', acc_tot(end)*100, subjects{subject}, paradigm);
    if save_res == 1
        acc_trials = acc_tot;
        save(['Results/Acc_by_blocks/' subjects{subject} paradigm], 'acc_trials'); 
    end
    
    %% PLOTS.
    
    if plot_figs == 1
        % Ensemble average.
        n_intensifications = 50/step; % max numb. of intensifications.
        figure(100+subject);
        for file = 1:size(avg, 4)
            subplot(size(avg, 4), 1, file);
            for stim = 1:size(avg, 2)
                if stim == stim_target(1, file) - 100
                    plot(time, avg(:, stim, n_intensifications, file), 'r');
                elseif size(stim_target, 1) == 2 && stim == stim_target(2, file) - 100
                    plot(time, avg(:, stim, n_intensifications, file), 'r');
                else
                    plot(time, avg(:, stim, n_intensifications, file), 'b');
                end
                hold on;
            end
        end
        
        % Only one run.
        file = 3;
        figure(200+subject);
        for stim = 1:size(avg, 2)
            grand_avg = mean(squeeze(avg(:, stim, n_intensifications, file)),2);
            if stim == stim_target(1) - 100
                h(stim) = plot(time*1000, grand_avg, 'r', 'LineWidth', 1);
            elseif size(stim_target, 1) == 2 && stim == stim_target(2) - 100
                h(stim) = plot(time*1000, grand_avg, 'r', 'LineWidth', 1);
            else
                h(stim) = plot(time*1000, grand_avg, 'b', 'LineWidth', 1);
            end
            hold on;
        end
        legend(h([stim_target(1)-100, stim_target(1)-100+1]), 'Target', 'Non target');
        xlabel('Time (ms)');
        ylabel('Amplitude (\muV)', 'interpreter', 'tex');
        set(gca,'FontName','Times New Roman','FontSize',12,'LineWidth',1,'XGrid',...
            'on','YGrid','on');
        
    end %plot_figs.
    
    if step_by_step == 1, pause, end
end
