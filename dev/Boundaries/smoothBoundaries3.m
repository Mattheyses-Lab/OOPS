function smoothBoundaries3(I)

boundaries = getPerfectBinaryBoundaries(I,"conn",8,"interpResolution",0.5,"method","loose");

% boundaries split into x and y components
boundariesX = boundaries{1}(:,2);
boundariesY = boundaries{1}(:,1);

boundariesXY = [boundariesX,boundariesY];

boundariesXY = approximateRespaceCurve(boundariesXY,0.25);
boundariesX = boundariesXY(:,1);
boundariesY = boundariesXY(:,2);

% number of points in the original boundary
nPoints = numel(boundariesX)

% determine the number of points to wrap onto the curve
wrapLength = floor(nPoints*0.04)

% "wrap" the curve onto itself
boundariesXWrap = [boundariesX(end-wrapLength:end-1); boundariesX(1:end); boundariesX(2:2+wrapLength)];
boundariesYWrap = [boundariesY(end-wrapLength:end-1); boundariesY(1:end); boundariesY(2:2+wrapLength)];

% number of points in the wrapped boundary
nPointsWrapped = numel(boundariesXWrap)

% determine window size from n points in data
windowSize = round(nPointsWrapped*0.02)

% smooth the wrapped curve (2nd output is window size)
[S,~] = smoothdata2([boundariesYWrap,boundariesXWrap],"sgolay",{[round(windowSize/2),round(windowSize/2)] [1,1]});

% remove the wrapped ends
S = S(1+wrapLength:end-wrapLength,:);

imshow2(I);

hold on

plot(boundariesX,boundariesY,'LineStyle','-','LineWidth',2,'Color',[0.5 0.5 1]);

plot(S(:,2),S(:,1),'LineStyle','-','LineWidth',2,'Color',[1 1 0]);



end