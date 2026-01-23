

function [holes] = extractFeatures(bw)
    bw_r = ~bw;

    labels = bwlabel(bw_r);

    c = max(labels(:));

    holes = c - 1;
end