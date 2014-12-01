function ExtractKeyFrames()
%  processes MIT video top down
% starts by removing 50 frames
% -Aaron Becker
% atbecker@uh.edu

format compact

tic
vidBirdseye = VideoReader('UP Birdseye Footage MIT Prores Smaller.mp4');
toc
nFrames = vidBirdseye.NumberOfFrames;

c= 1;  % counter for key frames
totalKeyFrames = 10;
for k = 1:30:300;%round(linspace(1,nFrames-1,totalKeyFrames))
   %save frame
   cdata = read(vidBirdseye,k);
   %show it on the screen
   figure(1)
   image(cdata)
   imwrite (cdata,['KeyFrames/frame',num2str(k,'%07d'),'.tiff']);
   display(['on frame ',num2str(c),' of ', num2str(totalKeyFrames), ', elapsed time is ', num2str(toc), ' seconds.']);
   imwrite (cdata,['KeyFrames/frameRel',num2str(c,'%07d'),'.tiff']);
   c=c+1;
   
end
