% tHIS CODE ATTEMPTS TO DO TEMPLATE MATCHING OF UMBRELLAS IN AN IMAGE
% Yao Wei, Aaron BEcker
%
%  TODO: try this with detecting multiple copies of the template
%  Try http://www.mathworks.com/help/images/ref/normxcorr2.html
%   I think it will be faster. See the example below.  
%   1.We need to count the peaks 
%   2.  probably should add a border around the original image so we can detect umbrellas on the edge.
%   
%   %
%%%%%%%%%%

%% Try with umbrellas: http://www.mathworks.com/help/images/ref/normxcorr2.html
% read and display the images
rgb = imread(['KeyFrames/frameRel',num2str(k,'%07d'),'.tiff']);
% convert rgb to YCbCr color space
YCBCR = rgb2ycbcr(rgb);
Igray = YCBCR(:,:,1);
T  = imread('Template1.bmp');

figure(1)
imshowpair(Igray,T,'montage')
title('image and template')
%Perform cross-correlation and display result as surface.
c = normxcorr2(T,Igray);
figure, surf(c), shading flat
title('cross correlation')

% %%  try using vision.TemplateMatcher
% htm=vision.TemplateMatcher;
% hmi = vision.MarkerInserter('Size', 10, ...
%     'Fill', true, 'FillColor', 'White', 'Opacity', 0.75);
% 
% % This script file aims to count number, classift color, and track
% k = 1;
% 
% % read and display the tiff files
% rgb = imread(['KeyFrames/frameRel',num2str(k,'%07d'),'.tiff']);
% % convert rgb to YCbCr color space
% YCBCR = rgb2ycbcr(rgb);
% Igray = YCBCR(:,:,1);
% 
% figure(1)
% image(Igray)
% 
% 
% 
% % % how to chose a template:
% % T = imcrop;
% % figure(3)
% % image(T);
% % imwrite (T,'Template2.bmp');
% 
% %use a single image as the template
% figure(2)
% T  = imread('Template2.bmp');
% 
% 
% % Find the [x y] coordinates of the chip's center
% Loc=step(htm,Igray,T);
% % Mark the location on the image using white disc
% J = step(hmi, Igray, Loc);
% 
% imshow(T); title('Template');
% figure(3); imshow(J); title('Marked target');
% 
% 
% %% example way http://www.mathworks.com/help/vision/ref/vision.templatematcher-class.html
% htm=vision.TemplateMatcher;
% hmi = vision.MarkerInserter('Size', 10, ...
%     'Fill', true, 'FillColor', 'White', 'Opacity', 0.75); I = imread('board.tif');
% 
% % Input image
%   I = I(1:200,1:200,:);
% 
% % Use grayscale data for the search
%   Igray = rgb2gray(I);
% 
% % Use a second similar chip as the template
%   T = Igray(20:75,90:135);
% 
% % Find the [x y] coordinates of the chip's center
%  %set(htm,'OutputValue','Metric matrix');
%  % Loc=step(htm,Igray,T);
%   %surf(Loc)
% 
%   
%   set(htm,'OutputValue','Best match location');
%   Loc=step(htm,Igray,T);
% % Mark the location on the image using white disc
%   J = step(hmi, I, Loc);
% 
% imshow(T); title('Template');
% figure; imshow(J); title('Marked target');