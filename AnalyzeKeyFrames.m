function AnalyzeKeyFrames()
%  processes MIT video top down
% starts by removing 50 frames
% -Aaron Becker
% atbecker@uh.edu

% IDEAS:  try http://www.mathworks.com/help/vision/examples/motion-based-multiple-object-tracking.html
%  also try  http://group.szbk.u-szeged.hu/sysbiol/horvath-peter-lab-overview.html


format compact

for k = 1 %:9

   %show it on the screen
   figure(1)
   rgb = imread(['KeyFrames/frameRel',num2str(k,'%07d'),'.jpg']);
   imshow(rgb)
   
   % what are the  sizes of the umbrellas?  
   % d = imdistline;
   % about 70 pixels
   gray_image = rgb2gray(rgb);
%imshow(gray_image);

 % imfindcircles finds circular objects that are brighter than the background.
 [centers, radii] = imfindcircles(rgb,[12 38],'ObjectPolarity','bright')      %#ok<NASGU,ASGLU> Variables 'centers' and 'radii' are needed to display the output with proper names.
   %  good rule of thumb is to choose the radius range such that Rmax < 3*Rmin 
   % and (Rmax- Rmin) < 100.
 viscircles(centers, radii,'EdgeColor','b');
 
end

%%
k = 1;
  figure(1)
  subplot(2,2,1)
   RGB = imread(['KeyFrames/frameRel',num2str(k,'%07d'),'.jpg']);
imshow(RGB)

YCBCR = rgb2ycbcr(RGB);

Ythresh = YCBCR(:,:,1)>32;
  subplot(2,2,2)
  imshow(Ythresh)
  % remove all object containing fewer than 30 pixels
bw = bwareaopen(Ythresh,400);
subplot(2,2,3)
  imshow(bw)
  
  
% try to count the bodies
  

cla
cc = bwconncomp(bw);

pxSize = 1:numel(cc.PixelIdxList);
for i = 1:numel(cc.PixelIdxList)
   pxSize(i) =  numel(cc.PixelIdxList{i});
   if pxSize(i)>5000
       % Need to separate these...
       bw(cc.PixelIdxList{i}) = 0;
   end
   
   
end
subplot(2,2,3)
imshow(bw)

subplot(2,2,4)
pxSizeS = sort(pxSize);

figure(3)
plot(pxSizeS,'.')
figure(1)
L = labelmatrix(cc);
rgb = label2rgb(L, 'jet', [.7 .7 .7], 'shuffle');
imshow(rgb)
s = regionprops(L, 'Area')
  
%   B = bwboundaries(bw,4,'noholes');
% imshow(bw)
% hold on
% text(10,10,strcat('\color{green}Objects Found:',num2str(length(B))))
% 
% for k = 1:length(B)
% boundary = B{k};
% plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 0.2)
%%
  figure
   RGB = imread(['KeyFrames/frameRel',num2str(k,'%07d'),'.jpg']);
imshow(RGB)

YCBCR = rgb2ycbcr(RGB);

  I = rgb2gray(RGB);
  threshold = graythresh(I);
bw = im2bw(I,threshold);

figure
imshow(bw)

% remove all object containing fewer than 30 pixels
bw = bwareaopen(bw,90);
imshow(bw)

% separate overlapping umbrellas:

% % try to separate them by eroding: doesn't work well, since it makes them
% % all smaller.  
% se = strel('disk',11);        
% erodedBW = imerode(bw,se);
%  figure, imshow(erodedBW)

% try to separate bby coloring all blobs that are bigger than x pixels, 


% another option: http://www.mathworks.com/help/vision/examples/tracking-pedestrians-from-a-moving-car.html

