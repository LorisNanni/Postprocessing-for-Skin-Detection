function [mask,class,img,SR,CC,BSR] = PostPpara(spm,TH1, TH2, TH3)


% PATTERN CLASSIFICATION
% CLASSI
% A -> foreground near without homogeneity
% B -> foreground "far"<-(not so far)
% C -> with body parts near without homogeneity
% D -> with body parts far
% E -> group near without homogeneity
% F -> group far
% G -> background considered as skin
% H -> default
% I -> foreground near whith homogeneity
% K -> with body parts near whith homogeneity
% L -> group near whith homogeneity

class = 'H';

% IPERPARAMETRI
% skin ratio
SRf = 0.2;
SRc = 0.137;
%SRg = 0.17;
% connected components
CCf = 2.322;
CCc = 3.89;
CCg = 6.9;

BSR=-1;
%get the binary image from the TA algorithm
img = TA(spm,0);

% compute essentials parameters
filledImg = imfill(img,'holes');
N = numel(img);
skinPixel = sum(filledImg(:)==1);
SR = skinPixel/N; %Skin Ratio su immagine senza buchi

imgO = bwareaopen(img,10); %remove groups of lonely pixel minor than 10px
CCstruct = bwconncomp(imgO);
CC = CCstruct.NumObjects;
sk = 0;

%compute parameters for classes I,K,L
regions = zeros(length(CCstruct.PixelIdxList), 1);%reset the array for regions
for j = 1 : length(CCstruct.PixelIdxList)
    regions(j) = length(CCstruct.PixelIdxList{j});%list of skin regions
end
largestRegion = max(regions);
skinArea = sum(regions);
SR2 = largestRegion/skinArea;%new skin ratio

imgO2 = bwareaopen(img, 1);%remove lonely pixels
CCstruct = bwconncomp(imgO2);
regions = zeros(length(CCstruct.PixelIdxList), 1);%reset regions' array
for j = 1 : length(CCstruct.PixelIdxList)
    regions(j) = length(CCstruct.PixelIdxList{j});%new list of skin regions
end
largestRegionO = max(regions);
LRR = largestRegionO/N;%largest region ratio

if SR > TH1
    if CC < TH2
        erodedImg = imerode(img,strel('disk',4));    
        imgSize = size(img);
        perimeter = 2 * imgSize(1) + imgSize(2);
        frame = sum(sum(erodedImg(1,:)==1)) + ...
            + sum(sum(erodedImg(1:end-1,1)==1)) + ...
            + sum(sum(erodedImg(1:end-1,end)==1));
        BSR = frame/perimeter;
        if BSR >= TH3
            class='G'; %background considered as skin
            sk=1; %go direct to pattern processing
        else
            %%%%
            imgO = bwareaopen(img,20);
            CCstruct = bwconncomp(imgO);
            CC = CCstruct.NumObjects;
        end
    end
end
if abs(SR-SRf) <= abs(SR-SRc) && sk==0 %foreground
        %foreground near A-I
        if CC == 2
            if SR2<.9995 && SR2>.9967
                class = 'I';
            else
                class = 'A';
            end
        elseif CC == 3
            if SR2 > .9730 && SR2 < 9992
                class = 'I';
            else
                class = 'A';
            end
        elseif CC == 1
            if LRR < .00008634 && LRR > .000003495
                class = 'I';
            else
                class = 'A';
            end
        %with body,arms near C-K
        elseif CC == 4
            if SR2 > .9701 && SR2 < .9979
                class = 'K';
            else
                class = 'C';
            end
        elseif CC == 5
            class = 'C';
        %group near E-L
        elseif CC == 6 || CC == 7
            if SR2 > .8736 && SR2 < .9984
                class = 'L';
            else
                class = 'E';
            end
        else
            class = 'E';
        end
elseif abs(SR-SRc) <= abs(SR-SRf) && sk==0 %with body parts
    if abs(CC-CCf) <= abs(CC-CCc) && abs(CC-CCf) <= abs(CC-CCg)
        %foreground "far" B-J
        class = 'B';
    elseif abs(CC-CCc) <= abs(CC-CCf) && abs(CC-CCc) <= abs(CC-CCg)
        %with body,arms far
        class = 'D';
    elseif abs(CC-CCg) <= abs(CC-CCc) && abs(CC-CCg) <= abs(CC-CCf)
        %group far
        class = 'F';
    end
end

% PATTERN PROCCESSING

BW = img;
radius=4;

switch class
    case {'I','K','L'}%homogeneity
        %{
        [labelBW, num] = bwlabel(BW,4);
        eulerBW = EulerIMG(labelBW, num);
        BW = immultiply(eulerBW,BW);
        %}
        
        imgO = bwareaopen(BW,30); %help function "regoinprops" in homog2
        temp = TA(spm,2); %spm normalized
        img2 = immultiply(imgO,temp);
        HomogBW = Homog2(img2);
        BW = immultiply(BW,HomogBW);
        
    case {'B','C','E','A'} %...near
        
        radius=8;
        erodedImg=imerode(BW,strel('disk',radius,4));
        erodedImg=bwareaopen(erodedImg, 2*3*radius); % Removing areas smaller than a structurig element
        dilatedImg=imdilate(erodedImg,strel('disk',radius,4)); % Dilating remaining areas
        BW=immultiply(dilatedImg,BW); % Restoring original holes in the remaining areas
        
    case {'D','F'} %...far
        %some rifiniment
        
        erodedImg=imerode(BW,strel('disk',radius,4));
        erodedImg=bwareaopen(erodedImg, 2*3*radius); % Removing areas smaller than a structurig element
        dilatedImg=imdilate(erodedImg,strel('disk',radius,4)); % Dilating remaining areas
        BW=immultiply(dilatedImg,BW); % Restoring original holes in the remaining areas
    
    case 'G'
        % Detect background area (the biggest)
        erodedImg(1,:) = 1;
        CC = bwconncomp(erodedImg);
        maxL = max(cellfun(@length, CC.PixelIdxList)); % Area of the bigger component

        % Extracting area where the biggest surface
        bgPixelList = CC.PixelIdxList{1};
        for i=1 : length(CC.PixelIdxList)
            if maxL == length(CC.PixelIdxList{i})
               bgPixelList = CC.PixelIdxList{i}; % Background
            end
        end

        % Copying background component from eBW
        bgArea = zeros(size(img));
        bgArea(bgPixelList)=1;

        % Heavy dilate of the extracted area to restore the previous erosion effect
        bgArea = imdilate(bgArea,strel('disk',10,4)); %dilatazione dell'immagine
        img = immultiply(img,~bgArea); % Removing bgArea from BW
        BW = imfill(img,'holes'); % Closing holes
    
    case 'H'
        disp("Err");
end

BW(find(BW<0))=0;
mask = BW;

end

