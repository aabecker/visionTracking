function determineUmbrellaColor
% Yao Wei and Aaron T. Becker

ImageOrigFile = 'Frame2color.tiff';
ImageGreyFile = 'Frame2grey.tiff';
ImageDataFile = 'Frame2Data.xls'; %#ok<NASGU>
ImageOrig = imread(ImageOrigFile);
ImageGrey = imread(ImageGreyFile); %#ok<NASGU>
imageFarsightFile = 'Frame2farsight.tiff';
imageFarsight = imread(imageFarsightFile ); %#ok<NASGU>
%1.) display original image
figure(1)

subplot(1,2,1)
image(ImageOrig)

%2.) display segmented image (from farsight)
subplot(1,2,2)
image(ImageOrig)  % TODO: how to display the outlines?
%colormap(gray)
%3.) read in the data file from farsight
ImageDataFile = 'Frame2Data.txt';
delimiter = '\t';
startRow = 2;
formatSpec = '%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';
fileID = fopen(ImageDataFile,'r');
ImageData = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
fclose(fileID);
subplot(1,2,1)
image(ImageOrig)
title('original')
%ID	centroid_x	centroid_y	centroid_z	volume	integrated_intensity	eccentricity	elongation	orientation	bounding_box_volume	sum	mean	minimum	maximum	sigma	variance	surface_gradient	interior_gradient	surface_intensity	interior_intensity	intensity_ratio	convexity	radius_variation	surface_area	shape	shared_boundary	t_energy	t_entropy	inverse_diff_moment	inertia	cluster_shade	cluster_prominence



%4.) display the (x,y) and radius values for each umbrella
cx = ImageData{2};
cy = ImageData{3};
area = ImageData{5};
radii = (area/pi).^.5;
subplot(1,2,2)
viscircles([cx,cy],radii)
title('Farsight Detections')



%6.) convert original image into HSV
ImageHSV = rgb2hsv(ImageOrig);
figure(2)
subplot(1,2,1)
image(ImageOrig)
title('original')
%colormap(gray)
hueVal = ImageHSV(:,:,1);

%7.) identify the average HUE of each umbrella
% instead, just use two for loops.  Calculate the HUE angle..

cx = ImageData{2};
cy = ImageData{3};
area = ImageData{5};
radii = (area/pi).^.5;
colors = zeros(size(cx));
hueAngle = hueVal*2*pi;
hueSin = zeros(size(cx));
hueCos = zeros(size(cx));
sf = 0.8;

meanGreen = 2.577;
meanRed = -0.4808;
meanBlue = -2.094;
meanPurple =-1.544;
meanOrange =-0.05;
meanColors = [meanGreen,meanRed,meanBlue,meanPurple,meanOrange];
colorNames = ['g','r','b','m','y'];

hues = zeros(size(cx));
for i= 1:numel(cx)
    n = 0;
    rad2search = sf*radii(i);
    for m = ceil(cy(i)-rad2search):floor(cy(i)+rad2search)
        for k = ceil(cx(i)-rad2search):floor(cx(i)+rad2search)
            if m<=size(hueAngle,1) && m>0 && k<=size(hueAngle,2) && k>0 ...
                    && (cy(i)-m)^2+(cx(i)-k)^2< sf*rad2search^2
                n = n + 1;
                % since HUe wraps around from [0,1], you need to evaluate
                % it as an angle.  Below is a numerically stable way to
                % calculate the mean:
                deltaSin = sin(hueAngle(m,k)) - hueSin(i);
                hueSin(i) = hueSin(i) + deltaSin/n;
                deltaCos = cos(hueAngle(m,k)) - hueCos(i);
                hueCos(i) = hueCos(i) + deltaCos/n;
                %hueAngle(m,k) = 50;
            end
        end
    end
    hues(i) = atan2(hueSin(i),hueCos(i));
    [~,colors(i)] = min(abs(meanColors - hues(i)));
end


subplot(1,2,2)
% draw the umbrellas in the classified colors:
image(ImageOrig)
for i = 1:numel(cx)
    rectangle('Position',[cx(i)-radii(i),cy(i)-radii(i),2*radii(i),2*radii(i)],'Curvature',[1,1],'FaceColor',colorNames(colors(i)))
end
title('Classified umbrellas')



%hues = atan2(hueSin,hueCos);


%8.) determine color of each umbrella:
%     0 at atime: black,
%     1 at a time: {Red, blue, green}
%     2 at a time:{purple, cyan, yellow},
%     3 at a time: {ideally white}

figure(3)
plot(sort((hues+pi)/(2*pi)),'.')
ylabel('Hue (H)')
xlabel('Umbrellas sorted by Hue')
for i = 1:numel(meanColors)
    h = line([1,numel(cx)],(meanColors(i)+pi)/(2*pi)*[1,1],'color',colorNames(i),'linewidth',2);
    uistack(h,'bottom');
end
title('Distribution of umbrella color')



%rectangle('Position',[1,2,5,10],'Curvature',[1,1],'FaceColor','r')


% for i=1:numel(x)
%     rad = floor(radii(i));
%
%     C = sqrt((rr-cx(i)).^2+(cc-cy(i)).^2)<=rad;
%     imshow(C)
%     meanGL = mean(grayImage(C))
% end
% cc=1:size(ImageGrey,1);
% rr=(1:size(ImageGrey,2))';
%
%
%
% for i = 1:numel(cx)
%     cxV = cx(i);
%    cyV = cy(i);
%    rV = floor(radii(i));
%
%     findCircleRegion=@(xx,yy) (xx-cxV).^2+(yy-cyV).^2 <= rV^2 ;
%
%     C=bsxfun(findCircleRegion,rr,cc); %Logical map of 2 circles
%     hueVal(C)
% end
%
% figure; imshow(C)




