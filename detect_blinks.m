% Function for blink detection using threshold algorithm.
% A blink is produced when a negative peaks exceeds the negative threshld
% and a postivie peak exceeds the postivie threhold. This must be produced
% in X samples. For more info see article sent to sensors.

function [blink, latency] = detect_blinks(cur_epoch, th)
    if nargin > 1
        min_limit = -th;
        max_limit = th;
    else
        min_limit = -200;
        max_limit = 200;
    end

    blink = false;
    idx = 1;
    latency = -1;

    while (idx < length(cur_epoch)) && (blink == false)
        if cur_epoch(idx) < min_limit
            cur_sample = idx;
            while (blink ==  false) && (idx < min((cur_sample + 200), length(cur_epoch)))
                idx = idx + 1;
                if (cur_epoch(idx) > max_limit)
                    blink = true;
                    latency = idx;
                end
            end
        else
             idx = idx + 1;
        end
    end
end