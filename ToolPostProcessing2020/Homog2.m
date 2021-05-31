function skin_mask = Homog2(spm)

%Parameters:
area = 300;
St = 40;
NdT = 1.5;
NsT = 0.22;
T = 0.2; %starting threshold 

%input image is pre processed and its spm with 0-1 prob range
temp = spm;

[height,width] = size(temp);
BW = zeros(height,width);
BW2 = zeros(height,width);
%BW2 = imbinarize(temp);

flag = 0;

%%%
%th = TA(spm,3);
%%%

%we select an initital threshold
%if the probability of a point is grater than T is labeled as skin
while T < 0.5 && flag == 0
    %binarize image with threshold T
    
    BW = temp > T;
    regions = regionprops(BW,'Area','BoundingBox','Image');
    count=0;
    
    for i=1 : length(regions)
        xTop = round(regions(i).BoundingBox(1));
        yTop = round(regions(i).BoundingBox(2));
        widthBox = round(regions(i).BoundingBox(3));
        heightBox = round(regions(i).BoundingBox(4));
        box = regions(i).Image; %the bounding box (image)

        %If the region is too small --> discard region
        if regions(i).Area < area
            a=1; b=1;
            for x=xTop : (xTop+widthBox)-1
                for y=yTop : (yTop+heightBox)-1
                    if BW(y,x)==1 && box(a,b)==1
                        temp(y,x)=0; 
                        BW(y,x)=0;
                    end
                    a=a+1;
                end
                a=1; b=b+1;
            end
        else
            %now let's check if region is homogeneous
            
            sigma = std2(box);
            BWedge = edge(spm, 'Sobel');
            Ne = sum(BWedge(:) == 1);
            Ns = regions(i).Area;
            Nd = max(widthBox, heightBox);
            
            if (~(sigma < St && ((Ne/Nd) <= NdT) || ((Ne/Ns) <= NsT)))
                %not homogeneous
                T = T+0.1;
                break
            else
                count=count+1;
                %founded an homogeneous region
                se = strel('square',3);
                dilatedBox = imdilate(box,se);
                
                %copy the dilated region in the original image
                a=1; b=1;
                for x=xTop : (xTop+widthBox)-1
                    for y=yTop : (yTop+heightBox)-1
                        BW(y,x) = dilatedBox(a,b);
                        a=a+1;
                    end
                    a=1; b=b+1;    
                end
                
                %when all regions are homogen -> exit
                if count==length(regions)
                    flag =1;
                end

            end

        end

    end
    
    T=T+0.1;
    
end

%imshowpair(BW,BW2,'montage');
skin_mask = BW;

end

