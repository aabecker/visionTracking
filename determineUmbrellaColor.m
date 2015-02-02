function determineUmbrellaColor
% Yao Wei and Aaron T. Becker

ImageOrigFile = 'Frame2color.tiff';
ImageGreyFile = 'Frame2color.tiff';
ImageDataFile = 'Frame2Data.xls';
ImageOrig = imread(ImageOrigFile);
ImageGrey = imread(ImageGreyFile);
imageFarsightFile = 'Frame2farsight.tiff';
imageFarsight = imread(imageFarsightFile );
%1.) display original image
figure(1)

subplot(1,2,1)
image(ImageOrig)

%2.) display segmented image (from farsight)
subplot(1,2,2)
image(imageFarsight)  % TODO: how to display the outlines?

%3.) read in the data file from farsight
ImageDataFile = 'Frame2Data.txt';
delimiter = '\t';
startRow = 2;
formatSpec = '%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';
fileID = fopen(ImageDataFile,'r');
ImageData = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
fclose(fileID);
%ID	centroid_x	centroid_y	centroid_z	volume	integrated_intensity	eccentricity	elongation	orientation	bounding_box_volume	sum	mean	minimum	maximum	sigma	variance	surface_gradient	interior_gradient	surface_intensity	interior_intensity	intensity_ratio	convexity	radius_variation	surface_area	shape	shared_boundary	t_energy	t_entropy	inverse_diff_moment	inertia	cluster_shade	cluster_prominence	



%4.) display the (x,y) and radius values for each umbrella
cx = ImageData{2};
cy = ImageData{3};
vol = ImageData{5};
radii = (vol/pi).^.5;
subplot(1,2,1)
    viscircles([cx,cy],radii)



%6.) convert original image into HSV
ImageHSV = rgb2hsv(ImageOrig);
figure(2)
subplot(1,2,1)
hueVal = ImageHSV(:,:,1);
image(ImageHSV)

%7.) identify the average HUE of each umbrella

% for i=1:numel(x)
%     rad = floor(radii(i));
%     
%     C = sqrt((rr-cx(i)).^2+(cc-cy(i)).^2)<=rad;
%     imshow(C)
%     meanGL = mean(grayImage(C))
% end
cc=1:size(ImageGrey,1); 
rr=(1:size(ImageGrey,2))';


 
for i = 1:numel(cx)
    cxV = cx(i);
   cyV = cy(i);
   rV = floor(radii(i));
    
    findCircleRegion=@(xx,yy) (xx-cxV).^2+(yy-cyV).^2 <= rV^2 ; 
    
    C=bsxfun(findCircleRegion,rr,cc); %Logical map of 2 circles
    hueVal(C)
end

figure; imshow(C)




%8.) determine color of each umbrella: 
%     0 at atime: black, 
%     1 at a time: {Red, blue, green} 
%     2 at a time:{purple, cyan, yellow}, 
%     3 at a time: {ideally white}