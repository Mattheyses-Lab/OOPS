function AzimuthCoherence = getAzimuthCoherence(AzimuthImage,OFImage)
% Author: Will Dean
% Still testing! not for use yet
% 
% fun = @(x) getLocalCoherence(x);
% 
% AzimuthCoherence = nlfilter(AzimuthImage,[3 3],fun); 
% 

    [H,W] = size(AzimuthImage);

    AzimuthCoherence = zeros([H,W]);

    loopMask = false([H,W]);

    loopMask(3:end-2,3:end-2) = true;

    for Idx = 1:numel(AzimuthImage)
        if loopMask(Idx)
            [r,c] = ind2sub([H,W],Idx);

            nHood = AzimuthImage(r-2:r+2,c-2:c+2);
            AzList = nHood(:);

            Rho = OFImage(Idx);
            Theta = AzimuthImage(r,c);

            AzimuthCoherence(Idx) = mean(Rho*(cos(Theta-AzList)).^2,'all');

        end
    end

end

function coherence = getLocalCoherence(I)

    r = ceil(size(I,1));
    c = ceil(size(I,2));

    AzList = I(:);

    Theta = I(r,c);

    coherence = mean((cos(Theta-AzList)).^2,'all');

end