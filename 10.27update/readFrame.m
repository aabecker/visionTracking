%% Read a Video Frame
% Read the next video frame from the video file.
function frame = readFrame(obj)
    frame = obj.reader.step();
end
