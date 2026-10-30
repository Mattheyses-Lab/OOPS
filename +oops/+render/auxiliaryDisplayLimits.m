function [value,bounds,ranges] = auxiliaryDisplayLimits(assignment,settings,values)
%AUXILIARYDISPLAYLIMITS Resolve one auxiliary channel's display policy.

arguments
    assignment (1,1) oops.model.AuxiliaryChannelAssignment
    settings (1,1) oops.config.Settings
    values = []
end

if isempty(values)
    statistics = assignment.getDisplayStatistics();
else
    statistics = assignment.getDisplayStatistics(values);
end

bounds = [statistics.Minimum statistics.Maximum];
ranges.Reset = bounds;
policy = settings.Display.auxiliaryPolicy(assignment.ChannelID);

ranges.Auto = oops.render.automaticDisplayRange( ...
    statistics,policy.AutoScaleMethod,bounds);

if policy.KeepAuto
    value = ranges.Auto;
elseif policy.Lock && ~isempty(policy.LockedRange)
    value = policy.LockedRange;
elseif isempty(assignment.DisplayRange)
    value = ranges.Reset;
else
    value = assignment.DisplayRange;
end

bounds = [min(bounds(1),value(1)) max(bounds(2),value(2))];
end
