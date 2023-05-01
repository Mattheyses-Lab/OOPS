function testVoronoiMidline(ObjectArray)

nObjects = numel(ObjectArray);

tic
for i = 1:nObjects

    try
        I = ObjectArray(i).RestrictedPaddedMaskSubImage;

        % method 1
        %Midline = traceObjectVoronoiMidline(I);
    
        % method 2
        % seems to be faster (and more elegant) but need to account for circular input/smoothing of curves
        [G,edges,Midline] = getObjectMidline(I,...
            "DisplayResults",false,...
            "BoundaryInterpolation",true,...
            "BoundarySmoothing",true...
            );
    catch ME
        msg = ME.getReport();
        disp(['Error at object ',num2str(i),': ',msg]);
    end

end

elapsedTime = toc;

disp(['Elapsed time: ',num2str(elapsedTime)]);

end