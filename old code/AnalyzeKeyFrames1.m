%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  @Author Wei Yao & Aaron Becker
%
%  @brief  What this does
%
%  @Date
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%

clear all; close all; clc; format compact

% This script file aims to count number, classift color, and track
k = 1; 

% read and display the tiff files
rgb = imread(['KeyFrames/frameRel',num2str(k,'%07d'),'.tiff']);
% imshow(rgb)

% measure the size of umbrella
% d = imdistline;  % radius is 30-35 pixels 

% convert rgb to YCbCr color space
YCBCR = rgb2ycbcr(rgb);
Ythresh = YCBCR(:,:,1)>32;

% imshow(Ythresh)

% removes small blobs
bw = bwareaopen(Ythresh,400);
imshow(bw)
% classify blobs as connected components
cc = bwconncomp(bw);

pxSize = numel(cc.PixelIdxList);
Umbrella_Count = 0;
Umbrella_Area = 0;
clot = 0;
for i = 1:numel(cc.PixelIdxList)
   pxSize(i) =  numel(cc.PixelIdxList{i});
%    adding overlap area of umbrellas
   if pxSize(i)>4000
       clot = clot+pxSize(i);
   else
%      counting umbrellas without overlap
       Umbrella_Area = Umbrella_Area+pxSize(i);
       Umbrella_Count = Umbrella_Count+1;
   end
  
end
% umbrella number
Umbrella_Count = Umbrella_Count + clot / (Umbrella_Area/Umbrella_Count);
display(Umbrella_Count)


% mnove this to a separate code -- a way to do ground truth
%http://www.mathworks.com/help/images/ref/imellipse.html?refresh=true

% inside a for loop (break out with a right mouse lcick or with a keyboard
% press

% select an umbrella, 
%h = imellipse;
%display number inside the circle
button = 1;
count = 0;
title('left click on all the umbrellas, right click to end')

xArr = [];
yArr = [];
while button ~= 3
    [x,y,button] = ginput(1);
    if button ~= 3
    count = count+1;
    htext=text(x,y,[num2str(count)]);
    set(htext,'color','b')
    xArr(count) = x; 
    yArr(count) = y; %#ok<*SAGROW>
    else
        %record positions and count so that we can check against our
        %algorithm
        save(['groundtruthFrame',num2str(k,'%07d')], 'xArr', 'yArr','k','count')
    end
    
end
    


