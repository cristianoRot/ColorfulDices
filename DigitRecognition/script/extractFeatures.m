% extractFeatures.m - Cristiano Rotunno 914317

function [holes, pa] = extractFeatures(bw)
    bw_r = ~bw;
    labels = bwlabel(bw_r);
    holes = max(labels(:)) - 1;
    
    perimeter = 0;
    total_area = 0;
    [h, w] = size(bw);
    
    for r = 2:h - 1
        for c = 2:w - 1
            if bw(r, c) == 1
                total_area = total_area + 1;
                
                v1 = bw(r, c - 1);
                v2 = bw(r, c + 1);
                v3 = bw(r + 1, c);
                v4 = bw(r - 1, c);
                
                if (v1*v2*v3*v4) == 0
                    perimeter = perimeter + 1;
                end
            end
        end
    end
    
    if total_area > 0
        pa = (perimeter ^ 2) / total_area;
    else
        pa = 0;
    end
end