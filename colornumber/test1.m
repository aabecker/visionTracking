%% 从视频里面分割图片
clc;
clear;
%% 读取视频
video_file='UP Birdseye Footage MIT Prores Smaller.mp4';
video=VideoReader(video_file);
frame_number=floor(video.Duration * video.FrameRate);
%% 分离图片
for i=1:10000:frame_number
    image_name=strcat('video3sup\',num2str(i));
    image_name=strcat(image_name,'.tiff');
    I=read(video,i);                               %读出图片
    imwrite(I,image_name,'tiff');                   %写图片
    I=[];
end