I = imread('G:\KeyFrames\frame19.tiff'); 
[d1,d2,d3] = size(I); 
if(d3 > 1) 
I = rgb2gray(I);%����ǻҶ�ͼ�Ͳ����ȱ任 
end 
I = double(I) / 255; 
I1 = uint8(255 * I * 0.5 + 0.5); 
imshow(I1);imwrite(I,'frame19grey.tiff')