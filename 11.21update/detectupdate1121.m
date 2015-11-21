%detect
clear, clc;
close all;
MOVIE_NAME = 'Umbrellatrack';
G.fig  = figure(1);
clf
set(G.fig,'Units','normalized','outerposition',[0 0 1 1],'NumberTitle','off','MenuBar','none','color','w');
writerObj = VideoWriter(MOVIE_NAME,'MPEG-4'); %http://www.mathworks.com/help/matlab/ref/videowriterclass.html
set(writerObj,'Quality',100, 'FrameRate', 30);
open(writerObj);
% ---------------------------------------
% Kalman filter initialization 初始化 Kalman filter, 这里初始化两个
% Track two umbrella, set Kalman Filter into KA
%% define main variables
u = .003; % define acceleration magnitude
dt = 1; %our sampling rate
tkn_x = .1; %measurement noise in the horizontal direction (x axis).
tkn_y = .1; %measurement noise in the horizontal direction (y axis).
HexAccel_noise_mag = 1;  %process noise: the variability in how fast the umbrella is speeding up
% - initialize R (Ez)
KA(1).R  = [tkn_x 0; 0 tkn_y]; % [[0.2845,0.0045]', [0.0045,0.0455]'];
KA(2).R  = [tkn_x 0; 0 tkn_y]; % [[0.2845,0.0045]', [0.0045,0.0455]'];
% - initialize Q (Ex) convert the process noise into covariance matrix
KA(1).Q  = [dt^4/4 0 dt^3/2 0; ...
            0 dt^4/4 0 dt^3/2; ...
            dt^3/2 0 dt^2 0; ...
            0 dt^3/2 0 dt^2].*HexAccel_noise_mag^2; % 0.01*eye(4);
KA(2).Q  = [dt^4/4 0 dt^3/2 0; ...
            0 dt^4/4 0 dt^3/2; ...
            dt^3/2 0 dt^2 0; ...
            0 dt^3/2 0 dt^2].*HexAccel_noise_mag^2; % 0.01*eye(4);
% - initialize P estimate of initial umbrella position variance (covariance matrix)
KA(1).P  = 100*eye(4);%KA(1).Q
KA(2).P  = 100*eye(4);%KA(2).Q
%% ---Define update equations(Coefficent matrices):A physics based model for
%---where we expect the umbrella to be[state transition (state + velocity)] +
%---[input control (acceleration)]
%--------------------------------------------------------------------------
% - initialize A --state transition matrix
KA(1).A  = [[1,0,0,0]',[0,1,0,0]',[dt,0,1,0]',[0,dt,0,1]'];
KA(2).A = [[1,0,0,0]',[0,1,0,0]',[dt,0,1,0]',[0,dt,0,1]'];
% - initialize B --input matrix
KA(1).B = [(dt^2/2); (dt^2/2); dt; dt]; % [0,0,0,KA(1).g]';
KA(2).B = [(dt^2/2); (dt^2/2); dt; dt]; % [0,0,0,KA(2).g]';
% - initialize H --observation matrix
KA(1).H  = [[1,0]', [0,1]', [0,0]', [0,0]'];
KA(2).H  = [[1,0]', [0,1]', [0,0]', [0,0]'];% measurement function H, apply to the state estimate Q to get our expect next/new measurement
%--------------------------------------------------------------------------
% - initialize kfinit
KA(1).kfinit = 0;
KA(2).kfinit = 0;
% - initialize x Q_estimate 
KA(1).x = zeros(100,4);
KA(2).x = zeros(100,4);
% ---------------------------------------
obj  = setupSystemObjects('First10Min.mp4'); % setup object video
num  = 0;
num2 = 0;
figure(1);
% cc = zeros(4000);
% cr = zeros(4000);
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
        centroids = []; % the umbrella detrctions extracted by the detection algo
        [centroids, bboxes, mask1] = detectObjects(frame, obj, xy);
        imshow(frame)
        title(['Frame ',num2str(num2), ' of' ])
        %extract ball
        if num2 == 1
            % - determine which two umbrellas to track
            % - the number of first umbrella
            KA(1).cc_tmp = centroids(38,1);
            KA(1).cr_tmp = centroids(38,2);
            % - the number of second umbrella
            KA(2).cc_tmp = centroids(55,1);
            KA(2).cr_tmp = centroids(55,2);
        else
            % - first
            KA(1).cc_tmp = KA(1).x(num2 - 1, 1);
            KA(1).cr_tmp = KA(1).x(num2 - 1, 2);
            % - second
            KA(2).cc_tmp = KA(2).x(num2 - 1, 1);
            KA(2).cr_tmp = KA(2).x(num2 - 1, 2);
        end
        for i = 1:length(KA)
            [cc(num2,i), cr(num2,i), radius, flag] = extract_umbrella(centroids, KA(i).cc_tmp, KA(i).cr_tmp); % predict the umbrellas
        end
        % ----------------------------------
        hold on
        for c = -0.9*radius: radius/20 : 0.9*radius
            r = sqrt(radius^2-c^2);
            for i = 1:size(cc, 2)
                plot(cc(num2, i) + c, cr(num2, i) + r, 'g.');
                plot(cc(num2, i) + c, cr(num2, i) - r, 'g.');
            end
        end
        % Slow motion! Do the kalman filter, predict next state of the
        % files with the last state and predicted motion
        for i = 1:length(KA)
            if KA(i).kfinit==0
                KA(i).xp = [MC/2,MR/2,0,0]';
            else
                KA(i).xp = (KA(i).A)*(KA(i).x(num2 - 1,:))' + (KA(i).B*u);
            end
          
         % Predict next covariance  
            KA(i).PP = (KA(i).A)*(KA(i).P)*(KA(i).A)' + (KA(i).Q); 
         % Kalman Gain   
            KA(i).K  = (KA(i).PP)*(KA(i).H)'/((KA(i).H)*(KA(i).PP)*(KA(i).H)' + (KA(i).R)); 
% %---------Trying to assign the detections to estimated track positions           
%             est_dist = pdist([(KA(i).xp)';[cc(num2,i), cr(num2,i)]]);
%             est_dist = sauareform(est_dist);
%             est_dist = est_dist(1:length(KA),length(KA):end);
%             
%             [asgn, cost] = ASSIGNMENTIOPTIMAL(est_dist);
%             asgn = asgn';
% %--------- Trying to reject the detection far from the observation
%          rej = [];
%          if asgn(i) > 0
%              rej(i) = est_dist(i,asgn(i)) < 50;
%          else
%              rej(i) = 0;
%          end
%          asgn = asgn.*rej;
%---------
        
         % Apply the assignment to the update
            KA(i).kfinit = 1;
            KA(i).x(num2,:) = ((KA(i).xp) + (KA(i).K)*([cc(num2,i), cr(num2,i)]' - (KA(i).H)*(KA(i).xp)))';
         % Update covariance estimation
            KA(i).P = (eye(4)-(KA(i).K)*(KA(i).H))*(KA(i).PP);
            KA(i).kfinit = KA(i).kfinit + 1;
        end
%--------- Trying to find the new detections and lost trackings
%--------- Anything that doesn't get assigned is a new tracking
%             new_trk = [];
%             new_trk = centroids(~ismember(1:size(centroids,1),asgn),:)';
%             if ~isempty(new_trk)
%                 centroids(:,i+1:i+size(new_trk,2)) = [new_trk; zeros(2,size(new_trk,2))];
%                 i = i + size(new_trk,2);%number of track estimates with new ones included
%             end
%           
        hold on
        for c = -1*radius: radius/20 : 1*radius
            r = sqrt(radius^2-c^2);
            for i = 1:length(KA)
                plot((KA(i).x(num2,1)) + c, (KA(i).x(num2,2)) + r, 'r.');
                plot((KA(i).x(num2,1)) + c, (KA(i).x(num2,2)) - r, 'r.');
            end
        end
        gframe = getframe(gcf);
		writeVideo(writerObj, gframe.cdata);
        pause(0.02)
        
        colorNames   = ['g','g','r','b','m','y','c','k'];
        for i = 1:size(cc, 2)
            [aveHue_tmp, numPixels_tmp, colors_tmp, imageClassified_tmp] = measureColor(fix([cc(num2,i)', cr(num2,i)']), fix([cc(num2,i)', cr(num2,i)']), frame);
            indx_tmp = numPixels_tmp > 0; %remove empty ones.
            color_matrix{num2, i} = colorNames(colors_tmp(indx_tmp));
        end
        % ------------------------------------------------------------
    end
    end

close(writerObj);
% --------------------------------------------------
for i = 1:size(cc,1)
    figure(2)
    subplot(2,1,1);
    for j = 1:size(cc,2)
        plot(cc(1:i,j), cr(1:i,j), 'r-');        
        hold on;
        set(gca, 'XLim', [min(cc(:)) - 5, max(cc(:)) + 5]);       
        xlabel('x represents the width of frame');
        set(gca, 'YLim', [min(cr(:)) - 5, max(cr(:)) + 5]);
        ylabel('y represents the height of frame');
        axis equal;
        title('Real');
    end
    % -------------------------------------------------
    subplot(2,1,2);
    % --
    for j = 1:length(KA)
        plot(KA(j).x(1:i,1), KA(j).x(1:i,2), 'g-');
        hold on;
        set(gca, 'XLim', [min(cc(:)) - 5, max(cc(:)) + 5]);       
        xlabel('x represents the width of frame');
        set(gca, 'YLim', [min(cr(:)) - 5, max(cr(:)) + 5]);
        ylabel('y represents the height of frame');
        axis equal;
        title('kalman Prediction');
    end
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
% 下面画 x 和 y 的图像变化图
figure(3)
subplot(2,1,1)
plot(1:size(cc,1), cc(:,1), 'k-');
hold on;
plot(1:size(cr,1), cr(:,1), 'k-');
for i = 1:size(cc,1)
    plot(i, cc(i,1), [color_matrix{i,1}, 'o']);
    hold on;
    plot(i, cr(i,1), [color_matrix{i,1}, '*']);
end
xlabel('x represents the number of frame');
ylabel('y represents the location of X and Y');
title('X and Y of th 38th');
legend({'oX', '*Y'});
% ---------------------
subplot(2,1,2);
plot(1:size(cc,1), cc(:,2), 'k-');
hold on;
plot(1:size(cr,1), cr(:,2), 'k-');
for i = 1:size(cc,1)
    plot(i, cc(i,2), [color_matrix{i,2}, 'o']);
    hold on;
    plot(i, cr(i,2), [color_matrix{i,2}, '*']);
end
xlabel('x represents the number of frame');
ylabel('y represents the location of X and Y');
title('X and Y of the 55th');
legend({'oX', '*Y'});
saveas(gcf, 'X_Y.png', 'png');
% -
% 下面画 x 和 y 的速度图像变化图
figure(4)
subplot(2,1,1)
axis equal;
plot(1:size(cc,1)-1, abs(cc(1:end-1,1) - cc(2:end,1)), 'k-');
hold on;
plot(1:size(cr,1)-1, abs(cr(1:end-1,1) - cr(2:end,1)), 'k-');
for i = 1:size(cc,1)-1
    plot(i, abs(cc(i,1) - cc(i+1,1)), [color_matrix{i,1}, 'o']);
    hold on;
    plot(i, abs(cr(i,1) - cr(i+1,1)), [color_matrix{i,1}, '*']);
end
xlabel('x represents the number of frame');
ylabel('y represents the speed of X and Y');
title('X and Y speed of th 38th');
legend({'oX', '*Y'});
% ---------------------
subplot(2,1,2)
axis equal;
plot(1:size(cc,1)-1, abs(cc(1:end-1,2) - cc(2:end,2)), 'k-');
hold on;
plot(1:size(cr,1)-1, abs(cr(1:end-1,2) - cr(2:end,2)), 'k-');
for i = 1:size(cc,1) - 1
    plot(i, abs(cc(i,2) - cc(i+1,2)), [color_matrix{i,2}, 'o']);   
    hold on;
    plot(i, abs(cr(i,2) - cr(i+1,2)), [color_matrix{i,2}, '*']);
end
xlabel('x represents the number of frame');
ylabel('y represents the speed of X and Y');
title('X and Y speed of the 55th');
legend({'oX', '*Y'});
saveas(gcf, 'X_Y_speed.png', 'png');

% ------------------------------------------------
%画速度变化图
% figure(4);
% for j = 1:size(cc,2)
%    ccV = [];
%    for i = 1:size(cc,1)-1
%        ccV = [ccV, sqrt((cc(i,j) - cc(i+1,j)).^2 + (cr(i,j) - cr(i+1,j)).^2)];
%    end
%    plot(ccV, 'b-*');
%    ylabel('Speed');
%    hold on;
% end
% --------------------------------------------------
%estimate image noise (R) from stationary umbrella
%posn = [cc(55:60)',cr(55:60)'];
%mp = mean(posn);
%diffp = posn - ones(6,1)*mp;
%Rnew = (diffp'*diffp)/5;