function colorconsensus
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
L = 100;
N = 200;
Xpos = rand(200,2)*L;
cols = ['r','g','b'];
Xcol = randi(3,N,1);

%set up figure
figure(1)
h = scatter(Xpos(:,1),Xpos(:,2),ones(N,1)*140,Xcol);
set(h,'marker','o')
k = 9; %number of nearest neighbors

IDX = knnsearch(Xpos,Xpos,'K',k);

for i = 1:N
    for j = 2:k
        %line([Xpos(IDX(i,1),1) Xpos(IDX(i,j),1)],[Xpos(IDX(i,1),2) Xpos(IDX(i,j),2)])
    end
end


maxIter = 100;
for i = 1:maxIter
    Xcoli = Xcol;
    for j = 1:N
        
        vc = histc(Xcol(IDX(j,:)),[1,2,3]);
        %assign most likely color
        if vc(1)>vc(2) && vc(1)>vc(3)
            Xcoli(j) = 1;
        elseif vc(2)>vc(1) && vc(2)>vc(3)
            Xcoli(j) = 2;
        elseif vc(3)>vc(1) && vc(3)>vc(2)
            Xcoli(j) = 3;
            %if tie randomly choose
        elseif vc(1) == vc(2) && vc(2) == vc(3)
            Xcoli(j) = randi(3,1);
        elseif vc(1) == vc(2)
            if rand(1)>0.5
                Xcoli(j) = 1;
            else
                Xcoli(j) = 2;
            end
            %if top two choices tie, randomly pick between them
        elseif vc(2) == vc(3)
            if rand(1)>0.5
                Xcoli(j) = 2;
            else
                Xcoli(j) = 3;
            end
        elseif vc(1) == vc(3)
            if rand(1)>0.5
                Xcoli(j) = 1;
            else
                Xcoli(j) = 3;
            end
        end
       if rand(1)<0.1  %each node has a small probability of changing each iteration
        Xcoli(j) = randi(3,1);
       end
        
    end
    Xcol = Xcoli;
    vc = histc(Xcol,[1,2,3])/N*100;
    title({['Round ',num2str(i)];['[rgb]=',num2str(vc')]})
              %update the figure
        set(h,'CData',Xcol);
        drawnow
        if max(vc) > 80
            break
        end
pause(0.1)
end 
        
        
