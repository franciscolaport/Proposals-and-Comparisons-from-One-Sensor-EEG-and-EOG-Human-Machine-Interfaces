function acc = threshold_detection_p300(area, stim_target)

     if size(stim_target, 1) > 1              % Row-Col paradigm.
        [~, row_max] = max(area(1:3));        % Max row area.
        [~, col_max] = max(area(4:end));      % Max col area.
        acc = (row_max == stim_target(1)-100 & col_max == stim_target(2)-100-3);
    else
        [~, idx] = max(area);
        acc = (idx == stim_target(1) -100);
     end
    
end