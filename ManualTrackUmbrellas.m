%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  @Author Wei Yao & Aaron Becker
%
%  @brief  Loads frames from a movie, starting at frameNumber.  It then
%  displays frame frameNumber.  If a textfile of x,y positions exists for a
%  text file ##NUM##.mat, where ##NUM## <= frameNumber, it loads
%  draggable markers and displays these at those xy positions.  The user
%  then can drag exisiting markers onto the center of the umbrellas, delete
%  by right clicking, and add new markers by left clicking.  The user
%  presses <enter> to go to the next frame, which saves the current frame
%  xy positions as frameNumber.mat, then loads frame frameNumber+framesToSkip
%
%  @Date May 6, 2015
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% you need the movie (vidName) in the same directory as the code
% you need a folder called 'manualPoints/' in the same directory as the
% code
% 'c' will switch between rgb images and a thresholded BW image
% 'd' deletes all marked points (in case they are terrible)
% 'k' will run k-means algorithm, using the current points as seed values.

%TODO: indicate on title when we are running k-means
% why do 2 figure pop up? remove one
% make it faster  ( click on 'run and time')
% indicate on the title when k-means is running (or turn mouse into
% hourglass)
%
%  Separeate code: we need to identify the color --(use Aaron's code, but
%  use k-means to figure out which pixels belong to the umbrella, and then

function ManualTrackUmbrellas(frameNumber, framesToSkip)
format compact
if nargin < 2
    framesToSkip = 15;
end
if nargin <1
    frameNumber = 2400; %1932;
end

useBW = true;
vidName = 'First10Min.mp4';  %much shorter!  Is 30 fps.  I want high resolutio0n data from 1:20 to 2:20.  (frame 2400 to 4200)
%vidName = 'UP Birdseye Footage MIT Prores Smaller.mp4';
dataFileName = 'manualPointsLowRes/';  %'manualPoints/';
titleString = 'Click to define object(s). Press <ENTER> to finish selection.';
figure(1)
imgax = gca;
hTitle    = title(imgax,'Loading movie.  Please wait');
imghandle = imhandles(imgax);
parentfig = ancestor(imgax,'figure');
set(imgax,'ButtonDownFcn','');
set(imghandle,'ButtonDownFcn',@placePoint);
set(parentfig,'KeyPressFcn',  @noMorePoints);
requestedvar = 'MarkedPoints';

processVideo = true;
if processVideo
    tic  %record the start time
    display(['Loading video: ',vidName]) %about 4 seconds
    vidBirdseye = VideoReader(vidName);
    toc %display how long it took to load.  My mac takes 4 seconds.  My PC takes 16s
    nFrames = vidBirdseye.NumberOfFrames;
    display(['Total Frames = ',num2str(nFrames)])  %10*60+4
    [cdata, bw, himage] = loadFrame(vidBirdseye, frameNumber,1);
else
    k=1; %#ok<UNRCH>
    rgb = imread(['KeyFrames/frameRel',num2str(k,'%07d'),'.tiff']);
    
    % convert rgb to YCbCr color space
    YCBCR = rgb2ycbcr(rgb);
    Ythresh = YCBCR(:,:,1)>32;
    % removes small blobs
    bw = bwareaopen(Ythresh,400);
    imshow(bw)
    %imshow(rgb)
end

    function placePoint(varargin)
        point_loc = get(imgax,'CurrentPoint');
        point_loc = point_loc(1,1:2);
        impoint2(imgax,point_loc);
        % save all the locations
        saveFrame();
    end

    function roi = impoint2(varargin)
        % impoint2: improved impoint object
        roi      = impoint(varargin{:});
        if ~useBW
            setColor(roi,'y')
        end
        % Add a context menu for adding points
        l        = findobj(roi,'type','hggroup');
        uic      = unique( get(l,'UIContextMenu') );
        for u = 1:numel(uic)
            uimenu( uic(u), 'Label', 'Delete', 'Callback', @deleteROI )
        end
        
        function deleteROI(src,evt) %#ok
            delete(roi);
            saveFrame();
        end
    end

    function [cdata, bw,himage] = loadFrame(vidReader, frameNum, firstTime,himage)
        tic %start a timer
        %loads video fream frameNum
        cdata = read(vidReader,frameNum);
        % convert rgb to YCbCr color space
        YCBCRim = rgb2ycbcr(cdata);
        Ythreshim = YCBCRim(:,:,1)>32;
        % removes small blobs
        bw = bwareaopen(Ythreshim,100);  %for high resolution, use 400 px as threshold.
        
        
        if firstTime==1
            %generate the image
            if useBW
                himage = imshow(bw);
            else
                himage = imshow(cdata);
            end
        else
            set(himage,'Cdata',bw)
            if useBW
                set(himage,'Cdata',bw)
            else
                set(himage,'Cdata',cdata)
            end
        end
                    imgax = gca;
            imghandle = imhandles(imgax);
            parentfig = ancestor(imgax,'figure');
            set(imgax,'ButtonDownFcn','');
            set(imghandle,'ButtonDownFcn',@placePoint);
            set(parentfig,'KeyPressFcn',  @noMorePoints);
            requestedvar = 'MarkedPoints';
        
        % TODO: Check if we we have any umbrella locations for this frame.  If so, delete markers and create new ones
        %impoint2(varargin)
        
        % try to load points from a data file.
        s = dir([dataFileName,'*.mat']); % s is structure array with fields name,
        % date, bytes, isdir
        file_list = {s.name}'; % convert the name field from the elements
        % of the structure array into a cell array
        % of strings.
        umbrellasClicked = 0;
        if numel(file_list) > 0
            cm = cell2mat(file_list);
            fileNums =  str2num(cm(:,1:end-4)); %#ok<ST2NM>  STR3DOUBLE causes failures
            indx = find(fileNums<=frameNumber,1,'last');
            %
            data = load([dataFileName,num2str(fileNums(indx),'%07d')], 'pointLocations');
            
            for i = 1:size(data.pointLocations,1)
                impoint2(imgax,data.pointLocations(i,:));
            end
            umbrellasClicked = size(data.pointLocations,1);
        end
        hTitle = title(imgax,['Frame ', num2str(frameNumber),', ', titleString,' ', num2str(umbrellasClicked),' umbrellas']);
        set(gcf,'units','normalized','outerposition',[0 0 1 1])
    end

    function pointLocations = saveFrame()
        pointLocations = getUmbrellaCenters(imgax);
        assignin('base',requestedvar,pointLocations);
        imsz = size(get(imhandles(imgca),'CData')); %#ok<NASGU>
        save([dataFileName,num2str(frameNumber,'%07d')], 'pointLocations','imsz','frameNumber');
        set( hTitle, 'String', ['Frame ', num2str(frameNumber),', ', titleString,' ', num2str(size(pointLocations,1)),' umbrellas ', num2str(toc,'%.1f') ])
    end

    function kMeanEstimates = kmeansAlgorithm( kMeanEstimates, data)
        maxCost=10^20;
        
        num = size(data,1);
        for iter = 1:3 % how many iterations of k-means?  5 seems to be enough
            
            k = size(kMeanEstimates,1);
            new_seeds = kMeanEstimates;
            set( hTitle, 'String', ['Frame ', num2str(frameNumber),', ', titleString,' ', num2str(k),' umbrellas ', num2str(toc,'%.1f'), ' iter: ',num2str(iter) ])
            drawnow
            
            tempx = repmat(data(:,1),1,k) - repmat(kMeanEstimates(:,1).',num,1);
            tempy = repmat(data(:,2),1,k) - repmat(kMeanEstimates(:,2).',num,1);
            distance = (tempx.^2 + tempy.^2);
            [min_dis,cluster_index] = min(distance.');
            
            for ii = 1:k
                new_seeds(ii,:) = mean(data(cluster_index == ii,:));
            end
            totalDis = sum(min_dis);
            
            new_seeds = new_seeds(~any(isnan(new_seeds),2),:); %remove NaN
            kMeanEstimates = new_seeds;
            display([num2str(iter),'.), total Dist =',num2str(totalDis), ' max cost=',num2str(maxCost)])
            
            if totalDis == maxCost
                break;
            end
            maxCost = totalDis;
        end
        set( hTitle, 'String', ['Frame ', num2str(frameNumber),', ', titleString,' ', num2str(k),' umbrellas ', num2str(toc,'%.1f'), ' k-means finished']);
    end

    function pointLocations = getUmbrellaCenters(imgax)
        roi = findall(imgax,'type','hggroup');
        pointLocations = NaN(numel(roi),2);
        for ii = 1:numel(roi)
            tmp = get(roi(ii),'children');
            pointLocations(ii,1) = get(tmp(1),'xdata');
            pointLocations(ii,2) = get(tmp(1),'ydata');
        end
    end

    function deleteUmbrellaCenters(imgax)
        roi = findall(imgax,'type','hggroup');
        for ii = 1:numel(roi)
            delete(roi(ii));
        end
    end

    function pointLocations = noMorePoints(~,evt)
        finished  = strcmpi(evt.Key,'return');
        pointLocations = [];
        %press 'c' to display bw or color images
        %      'd' to delete all markers
        %      'k' to run k-means
        %      'r' to reload previous markers
        if strcmpi(evt.Key,'d');
            deleteUmbrellaCenters(imgax);
        end
        if strcmpi(evt.Key,'r');
            [cdata, bw,himage] = loadFrame(vidBirdseye, frameNumber,2,himage);
        end
        if strcmpi(evt.Key,'c');
            useBW = ~useBW;
            color = 'b';
            if useBW
                set(himage,'Cdata',bw)
            else
                set(himage,'Cdata',cdata)
                color = 'y';
            end
            roi = findall(imgax,'type','hggroup');
            for ii = 1:numel(roi)
                tmp = get(roi(ii),'children');
                set(tmp(1),'color',color)
                set(tmp(2),'MarkerFaceColor',color)
                set(tmp(2),'MarkerEdgeColor',color)
            end
            %[cdata, bw,himage] = loadFrame(vidBirdseye, frameNumber,2,himage); %#ok<SETNU>
        end
        if strcmpi(evt.Key,'k');
            %call k-means, but first gather the needed data:
            kMeanEstimates = getUmbrellaCenters(imgax);
            [xcoord,ycoord] = ind2sub( size(bw), find(bw>0));
            nonBackgroundPx = [xcoord,ycoord];
            %kMeanEstimates are the xy pairs, one for each umbrella
            %data is every pixel that is not background.
            nonBackgroundPx = [nonBackgroundPx(:,2) nonBackgroundPx(:,1)];
            kMeansActual = kmeansAlgorithm( kMeanEstimates, nonBackgroundPx);
            % update the location of every mean value.
            deleteUmbrellaCenters(imgax)
            
            for i = 1:size(kMeansActual,1)
                impoint2(imgax,kMeansActual(i,:));
            end
        end
        
        if finished
            set( hTitle, 'String', ['SAVING Frame ', num2str(frameNumber),', ', titleString,' ', num2str(size(pointLocations,1)),' umbrellas ', num2str(toc,'%.1f') ])
            drawnow
            % Delete title, reset original functionality
            %delete(findall(parentfig,'tag','markImagePoints'));
            set(imghandle,'ButtonDownFcn','');
            set(parentfig,'KeyPressFcn','');
            pointLocations = saveFrame();
            
            % delete current markers.
            roi = findall(imgax,'type','hggroup');
            for ii = 1:numel(roi)
                delete(roi(ii));
            end
            
            %  load the next frame.
            frameNumber = frameNumber+framesToSkip;
            [cdata, bw,himage] = loadFrame(vidBirdseye, frameNumber,2,himage);
        end
    end
end

