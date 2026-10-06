% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef LocalBackground < handle
%LOCALBACKGROUND Local signal/background neighborhoods in pixels.
% Events carry Domain, Name, OldValue, and NewValue like DesmoSTORM.

    properties (Access=private)
        BufferRadius_ (1,1) double {mustBeFinite,mustBeInteger,mustBeNonnegative} = 3
        BackgroundWidth_ (1,1) double {mustBeFinite,mustBeInteger,mustBePositive} = 2
        ExcludeOtherObjects_ (1,1) logical = true
        ExcludeOtherBuffers_ (1,1) logical = true
    end

    properties (Dependent)
        BufferRadius
        BackgroundWidth
        ExcludeOtherObjects
        ExcludeOtherBuffers
    end

    events
        Changed
        LocalBackgroundChanged
    end

    methods

        function v = get.BufferRadius(obj)
        %GET.BUFFERRADIUS Return the stored BufferRadius setting.

            v = obj.BufferRadius_;
        end

        function set.BufferRadius(obj,v)
        %SET.BUFFERRADIUS Validate, store, and notify a LocalBackground setting change.

            obj.setValue("BufferRadius",v);
        end

        function v = get.BackgroundWidth(obj)
        %GET.BACKGROUNDWIDTH Return the stored BackgroundWidth setting.

            v = obj.BackgroundWidth_;
        end

        function set.BackgroundWidth(obj,v)
        %SET.BACKGROUNDWIDTH Validate, store, and notify a LocalBackground setting change.

            obj.setValue("BackgroundWidth",v);
        end

        function v = get.ExcludeOtherObjects(obj)
        %GET.EXCLUDEOTHEROBJECTS Return the stored ExcludeOtherObjects setting.

            v = obj.ExcludeOtherObjects_;
        end

        function set.ExcludeOtherObjects(obj,v)
        %SET.EXCLUDEOTHEROBJECTS Validate, store, and notify a LocalBackground setting change.

            obj.setValue("ExcludeOtherObjects",v);
        end

        function v = get.ExcludeOtherBuffers(obj)
        %GET.EXCLUDEOTHERBUFFERS Return the stored ExcludeOtherBuffers setting.

            v = obj.ExcludeOtherBuffers_;
        end

        function set.ExcludeOtherBuffers(obj,v)
        %SET.EXCLUDEOTHERBUFFERS Validate, store, and notify a LocalBackground setting change.

            obj.setValue("ExcludeOtherBuffers",v);
        end

        function S = toStruct(obj)
        %TOSTRUCT Serialize values without listeners or graphics objects.

            % Plain settings snapshot containing values only, without listeners.
            S = struct('BufferRadius',obj.BufferRadius, ...
                'BackgroundWidth',obj.BackgroundWidth, ...
                'ExcludeOtherObjects',obj.ExcludeOtherObjects, ...
                'ExcludeOtherBuffers',obj.ExcludeOtherBuffers);
        end

        function fromStruct(obj,S)
        %FROMSTRUCT Restore recognized settings through their validated setters.

            validateattributes(S,{'struct'},{'scalar'});

            % Names of the serialized fields to apply through the public setters.
            names = fieldnames(obj.toStruct());

            % Apply serialized fields through their validated public setting setters.
            for k = 1:numel(names)

                if isfield(S,names{k})
                    obj.(names{k}) = S.(names{k});
                end

            end

        end

    end

    methods (Access=private)

        function setValue(obj,name,value)
        %SETVALUE Validate the backing property before emitting change events.

            try

                % Private storage property corresponding to the public setting name.
                property = char(name + "_");

                % Stored setting value before validation and assignment.
                old = obj.(property);
                obj.(property) = value;

                % Stored/coerced setting value used in the change-event payload.
                value = obj.(property);

                if isequaln(old,value)
                    return;
                end

                % Change event carrying the domain, setting name, and old/new values.
                ev = oops.config.ChangeEvent("LocalBackground",name,old,value);
                notify(obj,'LocalBackgroundChanged',ev);
                notify(obj,'Changed',ev);
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end
end
