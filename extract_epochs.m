function [stim_count, stim_sum, stim_array] = extract_epochs(data, stim_codes, peaks, epoch_length, ch)
    
    % Get all stimuli > 100, since they represent the image codes.
    stimuli = stim_codes(stim_codes(:, 1) > 100, :);
    
    % Check if the detected peaks is equal to the number of stimuli.
    if length(peaks) ~= size(stimuli, 1)
        error('WARNING: Peaks and stimuli does not match!');
    end

    stim_count = zeros(sum(unique(stimuli(:, 1)) > 100), 1);
    stim_sum = zeros(epoch_length, length(stim_count));
    
%     peaks = peaks(1:300);
    
    for peak = 1:length(peaks)
        stim = stimuli(peak, 1) - 100;
        stim_count(stim) = stim_count(stim) + 1;
        epoch = data(peaks(peak):peaks(peak)+epoch_length-1, :);
        stim_sum(:, stim) = stim_sum(:, stim) + (epoch(:, ch) - mean(epoch(:,ch)));
        stim_array(:, stim_count(stim), stim) = (epoch(:, ch) - mean(epoch(:,ch)));
    %         stim_sum(:, stim) = stim_sum(:, stim) + epoch(:, 1);
    end
end