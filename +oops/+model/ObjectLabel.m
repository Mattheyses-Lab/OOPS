% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef ObjectLabel < handle
%OBJECTLABEL Define one project-level object label and its keyboard shortcut.

    properties (SetAccess=private)
        ID (1,1) string = ""
        Name (1,1) string = ""
        Hotkey (1,1) string = ""
        Color (1,3) double = [1 1 1]
        CreatedAt (1,1) datetime = datetime('now')
    end

    methods

        function obj = ObjectLabel(name,opts)
        %OBJECTLABEL Create a label with a stable ID and normalized hotkey.

            arguments
                name (1,1) string = ""
                opts.ID (1,1) string = ""
                opts.Hotkey (1,1) string = ""
                opts.Color (1,3) double = [1 1 1]
                opts.CreatedAt (1,1) datetime = datetime('now')
            end

            if strlength(opts.ID) == 0
                opts.ID = matlabx.utils.text.uniqueID();
            end

            validateattributes(opts.Color,{'numeric'},{'real','finite','>=',0,'<=',1});

            obj.ID = strtrim(opts.ID);
            obj.Name = strtrim(name);
            obj.Hotkey = lower(strtrim(opts.Hotkey));
            obj.Color = double(opts.Color);
            obj.CreatedAt = opts.CreatedAt;
        end

        function tf = hasHotkey(obj)
        %HASHOTKEY Report whether this label claims a keyboard shortcut.

            tf = strlength(obj.Hotkey) > 0;
        end

    end

    methods (Access=?oops.model.LabelRegistry)

        function update(obj,id,name,hotkey,color)
        %UPDATE Replace label fields after the registry validates their identity.

            obj.ID = id;
            obj.Name = name;
            obj.Hotkey = lower(hotkey);
            obj.Color = color;
        end

    end

end
