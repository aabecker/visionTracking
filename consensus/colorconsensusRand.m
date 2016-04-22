function colorconsensusRand
% this version tries to find the maximum among the others.  If there are
% ties, it randomly assigns.
%
% InitializationL
%   N agents (N=200) are randomly placed on a 2D region.  Each agent
%   initially selects a color from the set {R,G,B}.
%
% Goal: all agents to select the same color
%
% Process:
%    Turns are synchronized.  At each turn the robots
% check the current color of their k-nearest neighbors. update their
% current color based on the neighbors, their own color, and (perhaps)
% generating a random number Caveats:  each robot must run the same
% algorithm, each robot has a unique random number generator, all turns are
% synchronized, the set of potential colors is randomized -- no algorithm
% "everyone choose red" will work.
L = 100; %size of workspace
N = 200;%number of nodes
k = 7; %number of nearest neighbors
maxIter = 10000; %number of iterations to try to get consensus
bShowNN = false;

Xpos = rand(200,2)*L;
Xcol = randi(3,N,1);


%set up figure
figure(1); clf;
IDX = knnsearch(Xpos,Xpos,'K',k);

% This code draws the nearest neighbors
if bShowNN
    for i = 1:N
        for j = 2:k
            hl = line([Xpos(IDX(i,1),1) Xpos(IDX(i,j),1)],[Xpos(IDX(i,1),2) Xpos(IDX(i,j),2)]);
            set(hl,'color',[0.8,0.8,0.8]);
        end
    end
end
hold on
h = scatter(Xpos(:,1),Xpos(:,2),ones(N,1)*140,Xcol);
set(h,'marker','o')
hold off

%simulate
for i = 1:maxIter
    Xcoli = Xcol;
    for j = 1:N
        
        vc = histc(Xcol(IDX(j,:)),[1,2,3])/k;
        %randomly assign with probability proportional to most likely color
        r= rand(1);
        if r<vc(1)
            Xcoli(j) = 1;
        elseif r<vc(1)+vc(2)
            Xcoli(j) = 2;
        else
            Xcoli(j) = 3;
        end
    end
    Xcol = Xcoli;
    vc = histc(Xcol,[1,2,3])/N*100;
    title({['Round ',num2str(i)];['[bgr]=',num2str(vc')]})
    %update the figure
    set(h,'CData',Xcol);
    drawnow
    if max(vc) > 90
        break
    end
    %pause(0.1)
end


