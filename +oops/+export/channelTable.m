% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function T = channelTable(project)
%CHANNELTABLE Build one row per semantic project channel.
channels = project.Channels.Channels; n = numel(channels);
index = (1:n)'; name = strings(n,1); id = strings(n,1);
red = nan(n,1); green = nan(n,1); blue = nan(n,1); hex = strings(n,1);
colormap = strings(n,1); category = strings(n,1); primary = false(n,1); auxiliary = false(n,1);
primaryImages = zeros(n,1); auxiliaryImages = zeros(n,1);
for k = 1:n
    channel = channels(k); name(k) = channel.Name; id(k) = channel.ID;
    red(k) = channel.Color(1); green(k) = channel.Color(2); blue(k) = channel.Color(3);
    hex(k) = sprintf('#%02X%02X%02X',round(255*channel.Color));
    colormap(k) = channel.Colormap; category(k) = channel.ColormapCategory;
    primary(k) = channel.IsPrimary; auxiliary(k) = channel.IsAuxiliary;
    for group = reshape(project.Groups,1,[])
        primaryImages(k) = primaryImages(k)+sum(string({group.Images.PrimaryChannelID}) == channel.ID);
        auxiliaryImages(k) = auxiliaryImages(k)+sum(arrayfun(@(image) ...
            any(string({image.AuxiliaryChannels.ChannelID}) == channel.ID),group.Images));
    end
end
T = table(index,name,id,red,green,blue,hex,colormap,category,primary,auxiliary, ...
    primaryImages,auxiliaryImages,'VariableNames',{'Channel index','Channel name', ...
    'Channel ID','Red','Green','Blue','Hex color','Colormap','Colormap category', ...
    'Primary role','Auxiliary role','Primary image count','Auxiliary image count'});
end
