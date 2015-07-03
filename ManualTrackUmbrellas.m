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
%%

% you need the movie (vidName) in the same directory as the code
% you need a folder called 'manualPoints/' in the same directory as the
% code
% 'c' will switch between rgb images and a thresholded BW image
% 'd' deletes all marked points (in case they are terrible)

function ManualTrackUmbrellas(frameNumber, framesToSkip)

if nargin < 2
    framesToSkip = 23;
end
if nargin <1
    frameNumber = 1932;
end

useBW = true;

vidName = 'UP Birdseye Footage MIT Prores Smaller.mp4';
dataFileName = 'manualPoints/';
titleString = 'Click to define object(s). Press <ENTER> to finish selection.';
figure(1)
imgax = gca;
hTitle       = title(imgax,'Loading movie.  Please wait');
imghandle = imhandles(imgca);
parentfig = ancestor(imgax,'figure');
set(imgax,'ButtonDownFcn','');
set(imghandle,'ButtonDownFcn',@placePoint);
set(parentfig,'KeyPressFcn',  @noMorePoints);
requestedvar = 'MarkedPoints';



processVideo = true;

if processVideo
tic

display(['Loading video: ',vidName]) %about 4 seconds
vidBirdseye = VideoReader(vidName);
toc
nFrames = vidBirdseye.NumberOfFrames;
[cdata, bw] = loadFrame(vidBirdseye, frameNumber);
else
    k=1;
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
        pointLocations = saveFrame();
    end

    function roi = impoint2(varargin)
        % impoint2: improved impoint object
        roi      = impoint(varargin{:});
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

    function [cdata, bw] = loadFrame(vidReader, frameNum)
        tic %start a timer
        %loads video fream frameNum
        cdata = read(vidReader,frameNum); 
        % convert rgb to YCbCr color space
        YCBCRim = rgb2ycbcr(cdata);
        Ythreshim = YCBCRim(:,:,1)>32;
        % removes small blobs
        bw = bwareaopen(Ythreshim,400);
        %imshow(rgb)
        if useBW
            imshow(bw)
        else
            imshow(cdata)
        end
        imgax = gca;
        imghandle = imhandles(imgca);
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
            fileNums = str2num(cm(:,1:end-4));
            indx = find(fileNums<=frameNumber,1,'last'); 
            %
            data = load([dataFileName,num2str(fileNums(indx),'%07d')], 'pointLocations');
            
             for i = 1:size(data.pointLocations,1)
                impoint2(imgax,data.pointLocations(i,:));
             end 
             umbrellasClicked = size(data.pointLocations,1);
        end
        hTitle       = title(imgax,['Frame ', num2str(frameNumber),', ', titleString,' ', num2str(umbrellasClicked),' umbrellas']);
    end

    function pointLocations = saveFrame()
        roi = findall(imgax,'type','hggroup');
                pointLocations = NaN(numel(roi),2);
                for ii = 1:numel(roi)
                    tmp = get(roi(ii),'children');
                    pointLocations(ii,1) = get(tmp(1),'xdata');
                    pointLocations(ii,2) = get(tmp(1),'ydata');
                end
                assignin('base',requestedvar,pointLocations);
        imsz = size(get(imhandles(imgca),'CData')); %#ok<NASGU>
 
            save([dataFileName,num2str(frameNumber,'%07d')], 'pointLocations','imsz','frameNumber');
            set( hTitle, 'String', ['Frame ', num2str(frameNumber),', ', titleString,' ', num2str(size(pointLocations,1)),' umbrellas ', num2str(toc,'%.1f') ])
   
    end

function pointLocations = noMorePoints(~,evt)
        finished  = strcmpi(evt.Key,'return');
        pointLocations = [];
        %TODO:  'c' to display bw or color images
        %       'd' to delete all markers
        if strcmpi(evt.Key,'d');
            roi = findall(imgax,'type','hggroup');
                for ii = 1:numel(roi)
                    delete(roi(ii));
                end
        end
        if strcmpi(evt.Key,'c');
           useBW = ~useBW;
           loadFrame(vidBirdseye, frameNumber);
        end
        
        
        if finished
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
            [cdata, bw] = loadFrame(vidBirdseye, frameNumber); 
            
        end
        
    end


end

