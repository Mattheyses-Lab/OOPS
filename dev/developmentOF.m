function OF = developmentOF(I,method)
% I is a stack of emission images (mxnx4) at excitation polarizations 0°, 45°, 90°, and 135°
% testing different methods to calculate OF


switch method
    case 1 
        %% original method
        maximum = max(I,[],3);
        norm = I./maximum;
        a = norm(:,:,1)-norm(:,:,3);
        b = norm(:,:,2)-norm(:,:,4);
        OF = sqrt(a.^2+b.^2);
    case 2
        %% original method, but without normalization
        a = I(:,:,1)-I(:,:,3);
        b = I(:,:,2)-I(:,:,4);
        OF = sqrt(a.^2+b.^2);
    case 3
        %% original method, but normalizing to total intensity
        pxSum = sum(I,3);
        norm = I./pxSum;
        a = norm(:,:,1)-norm(:,:,3);
        b = norm(:,:,2)-norm(:,:,4);
        OF = sqrt(a.^2+b.^2);
    case 4
        %% original method, but normalizing to total intensity and multiplying by 2
        pxSum = sum(I,3);
        norm = (I./pxSum)*2;
        a = norm(:,:,1)-norm(:,:,3);
        b = norm(:,:,2)-norm(:,:,4);
        OF = sqrt(a.^2+b.^2);
    case 5
        %% original method, but normalizing to average intensity
        pxMean = mean(I,3);
        norm = (I./pxMean);
        a = norm(:,:,1)-norm(:,:,3);
        b = norm(:,:,2)-norm(:,:,4);
        OF = sqrt(a.^2+b.^2);
    case 6
        %% original method, but no normalization, instead dividing by average intensity at the end
        pxMean = mean(I,3);
        a = I(:,:,1)-I(:,:,3);
        b = I(:,:,2)-I(:,:,4);
        OF = sqrt(a.^2+b.^2)./pxMean;

end








imshow2(OF);
colormap(hot);
colorbar


end