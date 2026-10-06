% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef (ConstructOnLoad) ChangeEvent < event.EventData
    %CHANGEEVENT Same payload shape as DesmoSTORM settings events.

    properties (SetAccess=private)
        Domain (1,1) string
        Name (1,1) string
        OldValue
        NewValue
    end

    methods

        function obj = ChangeEvent(domain, name, oldValue, newValue)
        %CHANGEEVENT Describe one nested setting change for controller listeners.

            obj.Domain = domain;
            obj.Name = name;
            obj.OldValue = oldValue;
            obj.NewValue = newValue;
        end

    end
end
