clc;clear;close all;
imageDir = 'G:KeyFrames\';%'E:\Data\AaronBecker\images\';
files = dir(strcat(imageDir,'*.tif'));
exefile = 'G:\farsightExe\projproc.exe';%'C:\kedar\farsight\bin\farsight_git\exe\Release\projproc.exe';
defFile =  'G:\Program Files (x86)\FarSightSegmentation\BrianDef.xml';

for k = 1:length(files)
    disp(files(k).name);
    inputfileName = strcat(imageDir,files(k).name);
    outputfileName = strcat(inputfileName(1:length(inputfileName)-4),'_seg.tif');
    outputtxt = strcat(inputfileName(1:length(inputfileName)-4),'_seg.txt');
    cmdcommand = [exefile,' ',inputfileName,' ',outputfileName,' ',outputtxt,' ',defFile]
    [status cmdout] = system(cmdcommand)
end