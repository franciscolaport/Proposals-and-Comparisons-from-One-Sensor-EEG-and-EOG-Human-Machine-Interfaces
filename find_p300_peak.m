function [area, p300_peak, n400_peak, pp_diff] = find_p300_peak(ensemble_avg, fs, p300_win)

if nargin > 2 % Manually configured.
    p300_win_samples = floor((p300_win./1000).*fs);
    auto = false;
else
    p300_range = floor(([250, 450]./1000).*fs);  % We look for the max. value inside this range.
    auto = true;
end

n400_range = floor(([400, 600]./1000).*fs);
window_size = 100/1000*fs;                      % 100 ms.

for stim = 1:size(ensemble_avg, 2)
    if auto == true
        [~ , pos] = max(ensemble_avg(p300_range(1):p300_range(2), stim));
        pos = pos + p300_range(1);
        half_win = floor(window_size/2);
        p300_win_samples = [pos-half_win, pos+half_win];
    end
    
    % P300 peak.
    p300_peak(stim) = max(ensemble_avg(p300_win_samples(1):p300_win_samples(2), stim));
    
    % P300 area inside the P300 window.
    area(stim) = sum(ensemble_avg(p300_win_samples(1):p300_win_samples(2), stim));
    
    % Postive area.
    positive_area(stim) = sum(0.5*(ensemble_avg(p300_win_samples(1):p300_win_samples(2), stim) ...
        + abs(ensemble_avg(p300_win_samples(1):p300_win_samples(2), stim))));
    
    % Difference between the p300 peak and the minimun value before the
    % p300 window.
    pp_diff(stim) = p300_peak(stim) - min(ensemble_avg(1:p300_win_samples(1), stim));
    
    % N400 peak.
    [val, pos] = min(ensemble_avg(n400_range(1):n400_range(2), stim));
    n400_peak(stim) = val;
end
end