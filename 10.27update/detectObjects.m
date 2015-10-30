%% Detect Objects
% The |detectObjects| function returns the centroids and the bounding boxes
% of the detected objects. It also returns the binary mask, which has the 
% same size as the input frame. Pixels with a value of 1 correspond to the
% foreground, and pixels with a value of 0 correspond to the background.   
%
% The function performs motion segmentation using the foreground detector. 
% It then performs morphological operations on the resulting binary mask to
% remove noisy pixels and to fill the holes in the remaining blobs.  

function [centroids, bboxes, mask] = detectObjects(frame, obj, xy)
    % detect foreground
    YCBCRim = rgb2ycbcr(uint8(frame * 255));
    Ythreshim = YCBCRim(:,:,1)>32;
    mask = bwareaopen(Ythreshim,100);  %for high resolution, use 400 px as threshold.
    % perform blob analysis to find connected components
    [~, centroids, bboxes] = obj.blobAnalyser.step(logical(mask));
    centroids = xy;
    bboxes = [];
    for i = 1:size(xy,1)
        bboxes(i,:) = [xy(i,:), 5, 5];
    end
    bboxes = int32(bboxes);
end