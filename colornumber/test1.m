%% ����Ƶ����ָ�ͼƬ
clc;
clear;
%% ��ȡ��Ƶ
video_file='UP Birdseye Footage MIT Prores Smaller.mp4';
video=VideoReader(video_file);
frame_number=floor(video.Duration * video.FrameRate);
%% ����ͼƬ
for i=1:10000:frame_number
    image_name=strcat('video3sup\',num2str(i));
    image_name=strcat(image_name,'.tiff');
    I=read(video,i);                               %����ͼƬ
    imwrite(I,image_name,'tiff');                   %дͼƬ
    I=[];
end