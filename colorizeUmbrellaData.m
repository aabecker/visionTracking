function colorizeUmbrellaData
% Aaron T. Becker
% 7/29/2015
%
% takes data of umbrella positions
%   save([dataFileName,num2str(frameNumber,'%07d')], 'pointLocations','imsz','frameNumber');
%
% 1. get list of files that have data
% 2. for each data file:
% 3. load the xy locations of the umbrellas
% 4. load the corresponding image from the video
% 5. call k-means to get all pixels associated with each xy location
% 6. get the mean color of these pixels for each xy location
% 7. save the data [x,y,color, num pixels]
% 8. save the image (to make a movie?) (not done)
%
%
%  Problems:  often greens are classified as blue.
%             we can't detect 'off'.  Could we use value?  or Saturation?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% constants:
vidName = 'First10Min.mp4';  %much shorter!  Is 30 fps.  I want high resolutio0n data from 1:20 to 2:20.  (frame 2400 to 4200)
dataFileName = 'manualPointsLowRes/';  %'manualPoints/';
meanGreen = 2.577;
meanGreen2 = -3.14;
meanRed = -0.4808;
meanBlue = -2.094;
meanPurple =-1.544;
meanOrange =-0.05;
%meanBlack = -2.13;
meanCyan = -2.50; %MAYBE BIGGER
meanColors = [meanGreen,meanGreen2,meanRed,meanBlue,meanPurple,meanOrange,meanCyan];
colorNames = ['g','g','r','b','m','y','c','k'];



% 1. get list of files that have data
% try to load points from a data file.
filenames = dir([dataFileName,'*.mat']); % s is structure array with fields name,

% 1.b: load the video:
tic  %record the start time
display(['Loading video: ',vidName]) %about 4 seconds
vidBirdseye = VideoReader(vidName);
toc %display how long it took to load.  My mac takes 4 seconds.  My PC takes 16s

% 2. for each data file:
for i = 1:numel(filenames)
    
    % 3. load the xy locations of the umbrellas
    fileStr = filenames(i).name;
    data = load([dataFileName,fileStr], 'pointLocations');
    xy = data.pointLocations;
    % 4. load the corresponding image from the video
    
    frameNumber = str2double(fileStr(1:end-4));
    cdata = read(vidBirdseye,frameNumber);
    % convert rgb to YCbCr color space
    YCBCRim = rgb2ycbcr(cdata);
    Ythreshim = YCBCRim(:,:,1)>32;
    bw = bwareaopen(Ythreshim,100);  %for high resolution, use 400 px as threshold.
    % 5. call k-means to get all pixels associated with each xy location
    [xcoord,ycoord] = ind2sub( size(bw), find(bw>0));
    nonBackgroundPx = [xcoord,ycoord];
    nonBackgroundPx = [nonBackgroundPx(:,2) nonBackgroundPx(:,1)]; %TODO make matrix in one step.
    
    
    % 6. get the mean color of these pixels for each xy location
    [aveHue, numPixels,colors,imageClassified] = measureColor( xy, nonBackgroundPx, cdata); %#ok<ASGLU>
    
    
    % 7. save the data [x,y,color, num pixels]
    imsz = size(cdata);
    save([dataFileName,'Hue',num2str(frameNumber,'%07d')], 'xy','aveHue','numPixels','colors','imsz','frameNumber');
    % 8. save the image (to make a movie?)
    
    %display the image
    figure(1)
    subplot(2,1,1)
    imshow(cdata)
    title(num2str(frameNumber))
    subplot(2,1,2)
    imshow(imageClassified)
    drawnow
end

    function rgbC = getRGBfromName(charN)
        rgbC = bitget(find('krgybmcw'==charN)-1,1:3);
    end
    function [aveHue, numPixels,colors,imageClassified] = measureColor( xy, data, cdata)
        % xy is the locations of the center of each umbrella
        % data is the xy locations of the non-background pixels.
        % cdata is the color image r*c*3
        %find the pixels associated to each kMeanEstimate
        
        %convert the image to HSV
        ImageHSV = rgb2hsv(cdata);
        imHUE = ImageHSV(:,:,1);
        imVAL = ImageHSV(:,:,3);
        hueAngle = imHUE*2*pi;
        imageClassified = 0.2*ones(size(cdata));
        
        num = size(data,1);
        
        k = size(xy,1);
        aveHue = zeros(k,1);
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
        figure(2)
        imshow(imageClassified)
        for ii = 1:k
            text(xy(ii,1), xy(ii,2),num2str(aveHue(ii),'%.2f'),'color','w')
        end
        %set(texth,'color','w')
    end

end




