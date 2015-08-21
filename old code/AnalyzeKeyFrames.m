%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  @Author Wei Yao & Aaron Becker
%
%  @brief  analyzes some image.s  THis has a TODO list for Wei Yao
%
%  @Date
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function AnalyzeKeyFrames()
%  processes MIT video (top down camera on people holding umbrellas at
%  night)
%
% We have a folder full of images:  ./KeyFrames/frameRel###.jpg
%
% The full video is available: (it is private on youTube, so do not share it with non lab members)
% https://www.youtube.com/watch?v=MI-z0g1-0kk
%
% How to get an audio transcript (maybe):
% http://waxy.org/2014/01/dirty_fast_and_free_audio_transcription_with_youtube/
%
%
% Our eventual goals:
%
%    1. segment the image into forground (umbrellas) and background.
%    2.  segment the umbrellas into individual umbrellas (so we can count them)
%    3.  Track umbrellas frame-to-frame, so we know where the humans went
%    4.  classify the umbrella color (they had 3 LEDs that could each be on or off)
% -Aaron Becker
% atbecker@uh.edu



% 12/9/2014:
% For next week: Wei Yao 
% 1. learn to submit code onto github:  2 commits
% 2. try this code: http://blogs.mathworks.com/steve/2006/06/02/cell-segmentation/  it has a walk-through example.
% 3.    for two images, click on each umbrella so we have a ground-truth image
% 4.        if you have time, try this (can you find the code online?):
% C. Zhang, C. Sun, R. Su, and T. D. Pham, Segmentation of Clustered Nuclei Based on Curvature Weighting, In Image and Vision Computing New Zealand, Dunedin, New Zealand, 26-28 November 2012, pp.49-54.
% %http://dx.doi.org/10.1145/2425836.2425848
% 5. if you have time, close-caption a few minutes of the video.  Email Aaron where you ended.

% IDEAS:  try http://www.mathworks.com/help/vision/examples/motion-based-multiple-object-tracking.html
%  also try   http://group.szbk.u-szeged.hu/sysbiol/horvath-peter-lab-overview.html
%             http://www.mathworks.com/help/vision/examples/tracking-pedestrians-from-a-moving-car.html

%  google search:  matlab image segmentation
%                  matlab image threshold
%                  matlab image overlapping shapes

format compact


% %% Try one: looking for circles.  This doesn't work well
% for k = 1 %:9
%
%    %show it on the screen
%    figure(1)
%    rgb = imread(['KeyFrames/frameRel',num2str(k,'%07d'),'.jpg']);
%    imshow(rgb)
%
%    % what are the  sizes of the umbrellas?
%    % d = imdistline;
%    % about 70 pixels
%    gray_image = rgb2gray(rgb);
% %imshow(gray_image);
%
%  % imfindcircles finds circular objects that are brighter than the background.
%  [centers, radii] = imfindcircles(rgb,[12 38],'ObjectPolarity','bright')      %#ok<NASGU,ASGLU> Variables 'centers' and 'radii' are needed to display the output with proper names.
%    %  good rule of thumb is to choose the radius range such that Rmax < 3*Rmin
%    % and (Rmax- Rmin) < 100.
%  viscircles(centers, radii,'EdgeColor','b');
%
% end

%%
k = 1;
figure(1)
subplot(2,2,1)
RGB = imread(['KeyFrames/frameRel',num2str(k,'%07d'),'.jpg']);
imshow(RGB)
title('original image')

% convert the image from RGB to YCbCr.  It is wasy to threshold by the Y
YCBCR = rgb2ycbcr(RGB);

%Threshold the image
Ythresh = YCBCR(:,:,1)>32;
subplot(2,2,2)
imshow(Ythresh)
title('thresholded image')


% remove all object containing fewer than MINPIXELS pixels
MINPIXELS = 400;
bw = bwareaopen(Ythresh,MINPIXELS);
subplot(2,2,3)
imshow(bw)


% try to count the bodies
cc = bwconncomp(bw);

pxSize = 1:numel(cc.PixelIdxList);
for i = 1:numel(cc.PixelIdxList)
    pxSize(i) =  numel(cc.PixelIdxList{i});
    if pxSize(i)>4000
        % Need to separate these.  Perhaps k-means, based on average size
        % or we could try to erode:
        
        
        
        bw(cc.PixelIdxList{i}) = 0;  % sets all pixels in image {i} to be background
        
        % to image these, you can do :  figure(4)
        %                               plot( rem(cc.PixelIdxList{i}, 1076), floor(cc.PixelIdxList{i}/ 1076) ,'.')
        
        % Ideas:
%         1.erode this until it is no longer 1 connected component
%         2. find the centroids of each component
%         3. assign original pixels to the centroid
        
        
    end

end
subplot(2,2,3)

 se = strel('disk',11);
 erodedBW = imerode(bw,se);

imshow(bw)
title('remove small objects')
cc = bwconncomp(bw);

subplot(2,2,4)


figure(3)
pxSizeS = sort(pxSize);
plot(pxSizeS,'.')
xlabel('object, sorted by size')
ylabel('number of pixels')


figure(1)
L = labelmatrix(cc);
rgb = label2rgb(L, 'jet', [.7 .7 .7], 'shuffle');
imshow(rgb)
s = regionprops(L, 'Area')

title('show labelled regions')

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

