function dices_mask = segment_dices_initial(img)

    hsv = rgb2hsv(img);
    S = hsv(:,:,2);
    V = hsv(:,:,3);

    t1 = graythresh(S); 
    S_bin = imbinarize(S, t1);  

    S = imgaussfilt(S, 1.5);
    V = imgaussfilt(V, 1.5);

    edges_S = edge(S, 'prewitt');
    edges_V = edge(V, 'prewitt');

    edges_combined = edges_S | edges_V;

    dices_mask = S_bin | edges_combined;
end