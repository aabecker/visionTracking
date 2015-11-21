function [aveHue, numPixels,colors,imageClassified] = measureColor( xy, data, cdata)
% ---------------------------------------
% 添加颜色列表
meanGreen    = 2.577;
meanGreen2   = -3.14;
meanRed      = -0.4808;
meanBlue     = -2.094;
meanPurple   = -1.544;
meanOrange   = -0.05;
meanCyan     = -2.50;
meanColors   = [meanGreen,meanGreen2,meanRed,meanBlue,meanPurple,meanOrange,meanCyan];
colorNames   = ['g','g','r','b','m','y','c','k'];
% xy is the locations of the center of each umbrella
% data is the xy locations of the non-background pixels.
% cdata is the color image r*c*3
%find the pixels associated to each xy location
% returns the average hue 'aveHue' for each xy location, numPixels: the number of
% associated pixels, the classified 'colors', and an rgb image 'imageClassified' with
% all the classified objects recolored.

%convert the image to HSV
ImageHSV = rgb2hsv(cdata);
imHUE = ImageHSV(:,:,1);
imVAL = ImageHSV(:,:,3);
hueAngle = imHUE*2*pi;
imageClassified = 0.2*ones(size(cdata));

num = size(data,1);

k = size(xy,1);
aveHue = zeros(k,1);
aveVal = zeros(k,1);
numPixels = zeros(k,1);
colors = zeros(k,1);

tempx = repmat(data(:,1),1,k) - repmat(xy(:,1).',num,1);
tempy = repmat(data(:,2),1,k) - repmat(xy(:,2).',num,1);
distance = (tempx.^2 + tempy.^2);
[~,cluster_index] = min(distance.');
for ii = 1:k
    thisUmbrellaxy = data(cluster_index == ii,:);
    % figure out the average color
    linearInd = sub2ind(size(imHUE), thisUmbrellaxy(:,2), thisUmbrellaxy(:,1));
    hueSin = sum(sin(hueAngle(linearInd)));
    hueCos = sum(cos(hueAngle(linearInd)));
    aveHue(ii) = atan2(hueSin,hueCos);
    aveVal(ii) = mean(imVAL(linearInd));
    % count number of pixels associated with this mean
    numPixels(ii) = numel(thisUmbrellaxy(:,1));
    % classify the color
    [~,colors(ii)] = min(abs(meanColors - aveHue(ii)));
    if  ( colorNames(colors(ii)) == 'b'|| colorNames(colors(ii)) == 'c') && aveVal(ii) < 0.5
        colors(ii) = numel(colorNames); %black
    end
    rgbVal = getRGBfromName(colorNames(colors(ii)));
    for iii = 1:numPixels(ii) %TODO: fix this loop to be fast
        imageClassified(thisUmbrellaxy(iii,2), thisUmbrellaxy(iii,1),:) = rgbVal;
    end
end
%figure(2)
%for debugging:
%imshow(imageClassified)
%for ii = 1:k
%    text(xy(ii,1), xy(ii,2),num2str(aveHue(ii),'%.2f'),'color','w')
%end
%set(texth,'color','w')
function rgbC = getRGBfromName(charN)
rgbC = bitget(find('krgybmcw'==charN)-1,1:3);