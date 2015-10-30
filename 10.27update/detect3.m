%detect
clear,clc
format compact
% ---------------------------------------
% Kalman filter initialization
R=[[0.2845,0.0045]',[0.0045,0.0455]'];
H  = [[1,0]', [0,1]', [0,0]', [0,0]'];
Q  = 0.01*eye(4);
P  = 100*eye(4);
dt = 1;
A  = [[1,0,0,0]',[0,1,0,0]',[dt,0,1,0]',[0,dt,0,1]'];
g  = 1; % pixels^2/time step
Bu = [0,0,0,g]';
kfinit = 0;
x      = zeros(100,4);
% ---------------------------------------
obj  = setupSystemObjects('../First10Min.mp4'); % 创建视频对象
num  = 0;
num2 = 0;
figure(1);
cc = zeros(4000);
cr = zeros(4000);
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
        title(['Frame ',num2str(num2), ' of' ])
        %extract ball
        if num2 == 1
            cc_tmp = centroids(151,1);
            cr_tmp = centroids(151,2);
        else
            cc_tmp = x(num2 - 1, 1);
            cr_tmp = x(num2 - 1, 2);
        end
        [cc(num2), cr(num2), radius, flag] = extract_umbrella(centroids, cc_tmp, cr_tmp);%,fig1,fig2,fig3,fig15,i);
        hold on
        for c = -0.9*radius: radius/20 : 0.9*radius
            r = sqrt(radius^2-c^2);
            %——————————————
            %             scrsz = get(0,'ScreenSize');
            %         for i=1:length (cc)
            %             fig=figure;
            %——————————————
            plot(cc(num2) + c, cr(num2) + r, 'g.');
            plot(cc(num2) + c, cr(num2) - r, 'g.');
            %--------------------------
            %             set(fig,'Position',scrsz);
            %             M(i)=getframe(fig);
            %             close;
            %         end
            %             movie2avi(M,'out.avi', 'compression', 'none');
            %--------------------------
            
        end
        %Slow motion!
        if kfinit==0
            xp = [MC/2,MR/2,0,0]'; % Predict next state of the flies with the last state and predicted motion
        else
            xp = A*x(num2 - 1,:)' + Bu;
        end
        kfinit = 1;
        PP = A*P*A' + Q;  %predict next covariance
        K  = (PP*H')/(H*PP*H'+R); % Kalman Gain
        x(num2,:) = (xp + K*([cc(num2), cr(num2)]' - H*xp))';
        x(num2,:)
        display([cc(num2), cr(num2)]);
        P = (eye(4)-K*H)*PP;
        hold on
        
        for c = -1*radius: radius/20 : 1*radius
            r = sqrt(radius^2-c^2);
            %         %-------------------------------------------
            %           scrsz = get(0,'ScreenSize');
            %         for i=1:length (cc)
            %             fig=figure;
            %-------------------------------------------
            
            plot(x(num2,1) + c, x(num2,2) + r, 'r.')
            plot(x(num2,1) + c, x(num2,2) - r, 'r.')
            %         %-------------------------------------------
            %          set(fig,'Position',scrsz);
            %             M(i)=getframe(fig);
            %             close;
            %         end
            %             movie2avi(M,'out.avi', 'compression', 'none');
            %         %-------------------------------------------
        end
        pause(0.02)
    end
end
% --------------------------------------------------
% 下面画动态图
for i = 1:length(cc)
    figure(2)
    subplot(2,1,1);
    plot(cc(1:i), cr(1:i), 'r-');
    set(gca, 'XLim', [min(cc) - 5, max(cc) + 5]);
    xlabel('x represents the width of frame');
    set(gca, 'YLim', [min(cr) - 5, max(cr) + 5]);
    ylabel('y represents the height of frame');
    title('Real');
    % -------------------------------------------------
    subplot(2,1,2);
    plot(x(1:i,1), x(1:i,2), 'g-');
    set(gca, 'XLim', [min(x(:,1)) - 5, max(x(:,1)) + 5]);
    xlabel('x represents the width of frame');
    set(gca, 'YLim', [min(x(:,2)) - 5, max(x(:,2)) + 5]);
    ylabel('y represents the height of frame');
    title('kalman Prediction');
    saveas(gca, 'tmp.png', 'png');
    [AS] = imread('tmp.png');
    [imind_,cm_] = rgb2ind(AS,256);
    if i == 1
        imwrite(imind_,cm_, 'track.gif', 'gif', 'DelayTime',0.3);
    else
        imwrite(imind_,cm_, 'track.gif', 'gif', 'WriteMode','append', 'DelayTime',0.3);
    end
end
% -------------------------------------------------
figure(3);
plot(cc,'r.'); % width
hold on;
plot(cr, 'g.'); % hight
legend({'red is x position','green is y position'});
% ------------------------------------------------
%画速度变化图
figure(4);
ccV = zeros(length(cc)-1,1);
for i = 1:length(cc)-1
    ccV(i)= sqrt((cc(i) - cc(i+1)).^2 + (cr(i) - cr(i+1)).^2);
end
plot(ccV, 'b-*');
ylabel('Speed');
%
%  %actual position of the umbrella
%     plot(Q_loc(T));
%     ylim=get(gca,'ylim');
%     line([Q_loc(T);Q_loc(T)],ylim.','linewidth',2,'color','b');
%     legend('state predicted','measurement','state estimate','actual Quail position')
%     pause
% --------------------------------------------------
%estimate image noise (R) from stationary umbrella
%posn = [cc(55:60)',cr(55:60)'];
%mp = mean(posn);
%diffp = posn - ones(6,1)*mp;
%Rnew = (diffp'*diffp)/5;