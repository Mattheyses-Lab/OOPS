function [OFT,LFT,LFTO] =  LFT_OFT_loopless(Img, R, Nangles)
% performs line filter transform and orientation filter transform of an image


% Note: this function is modified from its original form (a mex file) to run quickly in MATLAB
% original functionality is unchanged, but code is now highly vectorized and runs in parallel

%% Original developers
% Developers: Zhen Zhang, Pakorn Kanchanawong
% Contact: biekp@nus.edu.sg
% 
% Reference:
% Sandberg, K. & Brega, M. Segmentation of thin structures in electron micrographs using orientation fields. J Struct Biol 157, 403-415 (2007). 

%% Original copyright
%--------------------------------------------------------------------------------
% Copyright (c) 2016, Zhen Zhang, Pakorn Kanchanawong
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
% 
% This software is provided by the copyright holders and contributors "as is" and 
% any express or implied warranties of merchantability and fitness for a particular 
% purpose are disclaimed. In no event shall the copyright owner or contributors 
% be liable for any direct, indirect, incidental, special, exemplary, or consequential 
% damages (including, but not limited to, procurement of substitute goods or services; 
% loss of use, data, or profits; or business interruption) however caused and on any 
% theory of liability, whether in contract, strict liability, or tort (including 
% negligence or otherwise) arising in any way out of the use of this software even if 
% advised of the possibility of such damage.
%--------------------------------------------------------------------------------

    % height and width of the input image
    [H,W] = size(Img);
    % store that as a 2-element row vector
    Isize = [H,W];
    % initialize our output images
    OFT = zeros([H,W]);
    LFT = OFT;
    LFTO = OFT;


    PI = 3.141593;
    AngleInterval = PI/Nangles;
    

    loopMask = false(Isize);
    % build mask with false border (width = R pixels)
    loopMask(R+1:end-R,R+1:end-R) = true;
    % row vector of linear idxs
    %loopIdxs = find(loopMask(:)).';
    % start a timer
    tic
    % these don't change, so no need to put them in the loop
    % row vector of line angles
    k = (-PI/2.0):AngleInterval:(PI/2.0-AngleInterval);
    % column vector of R
    q = (-R:1:R).';
    % the number of q and k indices
    nK = numel(k);
    nQ = numel(q);
    % these terms do not change, so we can pull them out of the loop
    % k = line angle, q = line length
    qkX = floor(q.*cos(k)+0.5);
    qkY = floor(q.*sin(k)+0.5);
    % LFT vectorized/parallelized (in progress)
    parfor Idx = 1:numel(Img) % linear idxs
        if loopMask(Idx)
            [j,i] = ind2sub(Isize,Idx);
            % q by k matrices of x and y coordinates of our integration lines
            x = max(min(i + qkX,W),1);
            y = max(min(j - qkY,H),1);
            % now convert x and y coordinates to a vector of linear indices,
            % get the intensities for each index, 
            % reshape output to q by k,
            % then take sum along q and max along k, 
            % use the idx of the max to get idx to max k
            [maxI,maxIdx] = max(sum(reshape(Img(sub2ind(Isize,y(:),x(:))),nQ,nK),1));
            LFT(Idx) = maxI/(2*R+1);
            LFTO(Idx) = k(maxIdx);
        end
    end
    % display elapsed time
    LFT_time = toc;
    disp(['LFT: ',num2str(LFT_time),' seconds elapsed']);



%% highly vectorized LFT code
% tic
%     [maxI,maxIdx] = max(reshape(sum(reshape(Img(sub2ind(Isize,...
%         max(min(repmat([R+1:1:H-R].',1,H-2*R,nQ*nK)-reshape(floor(q.*sin(k)+0.5),1,1,nQ*nK),H),1),...
%         max(min(repmat([R+1:1:W-R],W-2*R,1,nQ*nK)+reshape(floor(q.*cos(k)+0.5),1,1,nQ*nK),W),1))),...
%         H-2*R,W-2*R,nQ,nK),3),H-2*R,W-2*R,nK),[],3);
% 
%     LFT(loopMask) = maxI./(2*R+1);
%     LFTO(loopMask) = k(maxIdx);
% toc
%% end highly vectorized LFT code


    k_column = repmat(k,nQ,1);
    k_column = k_column(:);
    %start timer
    tic
    parfor Idx = 1:numel(Img)
        if loopMask(Idx)
            [j,i] = ind2sub(Isize,Idx);

            x = max(min(i + floor(q.*cos(k)+0.5),W),1);
            y = max(min(j - floor(q.*sin(k)+0.5),H),1);
    
            LineSums = sum(reshape(LFT(Idx)*cos(2*(LFTO( sub2ind(Isize,y(:),x(:)) ) -k_column )),nQ,nK),1);
    
            OFT(Idx) = max(LineSums);
        end
    end
    OFT_time = toc;
    disp(['OFT: ',num2str(OFT_time),' seconds elapsed']);

end