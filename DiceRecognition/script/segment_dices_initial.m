function dices_mask = segment_dices_initial(img)

    hsv = rgb2hsv(img);
    S = hsv(:,:,2);
    V = hsv(:,:,3);

    t1 = graythresh(S); 
    S_bin = imbinarize(S, t1);  

    S_med = medfilt2(S, [9 9]); 
    V_med = medfilt2(V, [9 9]);

    S_smooth = imgaussfilt(S_med, 1.5);
    V_smooth = imgaussfilt(V_med, 1.5);

    edges_S = edge(S_smooth, 'prewitt');
    edges_V = edge(V_smooth, 'prewitt');

    edges_combined = edges_S | edges_V;

    dices_mask = S_bin | edges_combined;
end