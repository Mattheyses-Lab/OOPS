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

switch policy.AutoScaleMethod
    case "Light contrast"
        ranges.Auto = [statistics.Percentile0_5 statistics.Percentile99_95];
    case "Medium contrast"
        ranges.Auto = [statistics.Percentile0_5 statistics.Percentile99_9];
    case "Strong contrast"
        ranges.Auto = [statistics.Percentile1 statistics.Percentile99_5];
    case "Zero to max"
        ranges.Auto = [0 statistics.Maximum];
    case "Data range"
        ranges.Auto = bounds;
end

if ranges.Auto(2) <= ranges.Auto(1)
    ranges.Auto = bounds;
end

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
