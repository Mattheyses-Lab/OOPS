function plotObjectMidlineScan(source,scanMode)

    % get the project data structure
    OOPSData = guidata(source);

    % get current object
    cObject = OOPSData.CurrentObject;

    % return if empty
    if isempty(cObject)
        uialert(OOPSData.Handles.fH,'No object found','Error')
        return
    end

    % get Midline points
    P = cObject.Midline;

    % get padded Order subimage
    Order = cObject.PaddedOrderSubImage;

    % get padded Mask subimage
    Mask = cObject.paddedSubImage;

    % set pixels outside object to NaN
    Order(~Mask) = NaN;


    % set up figure
    fig = uifigure(...
        'Name','Midline scan',...
        'Visible','off');
    ax = uiaxes(fig,...
        'Units','normalized',...
        'Position',[0 0 1 1]);
    ax.XLabel.String = 'Distance';
    ax.YLabel.String = 'Order';

    % perform linescan based on scanMode
    switch scanMode
        case 'order'
            [D,Y] = linescan_curve(Order,P,"AlongStep",0.1,"CrossStep",0.1,"Width",5);
            yyaxis(ax,"left")
            plot(ax,D,Y,'Color',[0 0 1]);
        case 'order+intensity'
            I = cObject.PaddedAverageIntensityImage;
            I(~Mask) = NaN;
            [D,Y] = linescan_curve({Order,I},P,"AlongStep",0.1,"CrossStep",0.1,"Width",5);

            yyaxis(ax,"left");
            plot(ax,D,Y{1});
            yyaxis(ax,"right");
            plot(ax,D,Y{2});
            ax.YLabel.String = 'Intensity';
        case 'order+reference'
            R = double(cObject.PaddedReferenceSubImage);
            R(~Mask) = NaN;
            [D,Y] = linescan_curve({Order,R},P,"AlongStep",0.1,"CrossStep",0.1,"Width",5);

            yyaxis(ax,"left");
            plot(ax,D,Y{1});
            yyaxis(ax,"right");
            plot(ax,D,Y{2});
            ax.YLabel.String = 'Reference intensity';
    end

    movegui(fig,'center');
    fig.Visible = 'on';

end