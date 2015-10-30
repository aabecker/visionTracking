%detect
clear,clc
% ---------------------------------------
% Kalman filter initialization
R = [[0.2845,0.0045]', [0.0045,0.0455]'];
H = [[1,0]', [0,1]', [0,0]', [0,0]'];
Q = 0.01*eye(4);
P = 100*eye(4);
dt = 1;
A = [[1,0,0,0]',[0,1,0,0]',[dt,0,1,0]',[0,dt,0,1]']; %state update matrice
g = 6; % pixels^2/time step
Bu = [0,0,0,g]';
kfinit = 0;
x = zeros(100,4);
% ---------------------------------------
obj = setupSystemObjects('First10Min.mp4'); % 创建视频对象
num  = 0;
num2 = 0;
figure(1);
cc = [];
cr = [];
while ~isDone(obj.reader)
    frame = readFrame(obj);
    [MR, MC] = size(frame);
    num = num + 1;
    n = 1;
    try
        load(['manualPointsLowRes\Hue\Hue', num2str(num,'%07d'), '.mat']);
        n = 0;
    catch
    end
    if n == 0
        num2 = num2 + 1;
        [centroids, bboxes, mask1] = detectObjects(frame, obj, xy);
        imshow(frame)
        Imwork = double(frame);
        %extract ball
        if num2 == 1
            cc_tmp = centroids(10,1);
            cr_tmp = centroids(10,2);
        else
            cc_tmp = cc(num2 - 1);
            cr_tmp = cr(num2 - 1);
        end
        [cc(num2), cr(num2), radius, flag] = extract_umbrella(centroids, cc_tmp, cr_tmp);%,fig1,fig2,fig3,fig15,i);
        hold on
        for c = -0.9*radius: radius/20 : 0.9*radius
            r = sqrt(radius^2-c^2);
            plot(cc(num2) + c, cr(num2) + r, 'g.');
            plot(cc(num2) + c, cr(num2) - r, 'g.');
        end
        %Slow motion!
        if kfinit==0
            xp = [MC/2,MR/2,0,0]';
        else
            xp=A*x(num2 - 1,:)' + Bu; % Predict next state of the flies with the last state and predicted motion.
        end
        kfinit = 1;
        PP = A*P*A' + Q; %predict next covariance
        K = PP*H'*inv(H*PP*H'+R); % Kalman Gain
        x(num2,:) = (xp + K*([cc(num2), cr(num2)]' - H*xp))';
        x(num2,:)
        [cc(num2), cr(num2)];
        P = (eye(4)-K*H)*PP; % update covariance estimation.
        hold on
        for c = -1*radius: radius/20 : 1*radius
            r = sqrt(radius^2-c^2);
            plot(x(num2,1) + c, x(num2,2) + r, 'r.')
            plot(x(num2,1) + c, x(num2,2) - r, 'r.')
        end
        pause(0.02)
    end
end
% --------------------------------------------------
figure
plot(cc,'r*')
hold on
plot(cr,'g*')
%end

%estimate image noise (R) from stationary ball
posn = [cc(55:60)',cr(55:60)'];
mp = mean(posn);
diffp = posn - ones(6,1)*mp;
Rnew = (diffp'*diffp)/5;