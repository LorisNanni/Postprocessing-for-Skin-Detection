function skin = TA(spm,opt)

% get in input an spm image --> skin probability map aka score image
% ta gets the thresholds of spm image and obtains 2 differente probability skin approach
% firts image has pixels with good probability of being skin
% second has uncertain pixel map

if opt==1 %return binarize image
    temp = double(255-spm);
    temp = temp./255;
    skin = imbinarize(temp);
    return
elseif opt==2 %return spm "normalized"
    temp = double(255-spm);
    temp2 = temp./255;
    skin = temp2;
    return
end


% TA Algorithm

[width, height] = size(spm);
N = width*height;

Sold = zeros(width,height);
BW1 = zeros(width,height);
BW2 = zeros(width,height);

% Divide the spm into three set of regions with Otsu's algorithm
thresh = multithresh(spm,9);
try seg_spm =imquantize(spm,thresh);
catch
    try
        thresh = multithresh(spm,4);
        seg_spm =imquantize(spm,thresh);
    catch
        thresh = multithresh(spm,1);
        seg_spm =imquantize(spm,thresh);
    end
end

%get threshold
if opt==3
    ret = max(thresh);
    skin = double(ret);
    skin=skin/255;
    return
end

% So is the initial set of skin-like pixel
% We take the higher(higher probability of being skin) regions of the three
temp = seg_spm <= 4;
temp2 = double(255-spm);

% Sold will be composed by the pixel in the highest threshold
% after the Ots's algorithm is applyed

i=1;
for x=1 : width
    for y=1: height
        if temp(x,y)== 1
            Sold(x,y) = temp2(x,y);
            val(i) = temp2(x,y); %need only values for fcm (without any zeros ecc)
            i=i+1;
        end
    end
end

% FCM clustering algorithm is applied on the set Sold to group and
% discard non-skin pixel locations within it.
try
    %Two clusters
    %centers = fcm(val(:) ,S); %fuzzy c-means
    [idx,centers] = kmeans(val(:),2);
    
    %assign zero or one depending on the minimum distance
    for i=1 : N
        if Sold(i) ~= 0
            if abs(Sold(i)-centers(1)) < abs(Sold(i)-centers(2))
                BW1(i)=1;
            else
                BW2(i)=1;
            end
        end
    end
    
    %imshowpair(BW1,BW2,'montage');
    
    %BW1 contains pixels that are skin with good probability
    %BW2 contains uncertain skin pixel
    if sum(BW1(:)==1)<sum(BW2(:)==1)
        swap = BW1;
        BW1 = BW2;
        BW2 = swap;
    end
    
    % S1 and S2 contain the score values of BW1 and BW2
    % array multiply
    S1 = bsxfun(@times,BW1,Sold);
    S2 = bsxfun(@times,~BW1,Sold);
    
    NBW = BW1+BW2;
    skin=NBW;
    
    %edge refinement
    edgeBW = edge(NBW, 'canny');
    skin = double(NBW) - double(edgeBW);
    
catch
    skin = spm<=128;
end


end

