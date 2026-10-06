% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef IO < handle
%IO User-facing import/export preferences.
% Events carry Domain, Name, OldValue, and NewValue like DesmoSTORM.

    properties (Access=private)
        DefaultFolder_ (1,1) string = ""
        ImageFormat_ (1,1) string = "tif"
        TableFormat_ (1,1) string = "csv"
    end

    properties (Dependent)
        DefaultFolder
        ImageFormat
        TableFormat
    end

    events
        Changed
        IOChanged
    end

    methods

        function v = get.DefaultFolder(obj)
        %GET.DEFAULTFOLDER Return the stored DefaultFolder setting.

            v = obj.DefaultFolder_;
        end

        function set.DefaultFolder(obj,v)
        %SET.DEFAULTFOLDER Validate, store, and notify a IO setting change.

            obj.setValue("DefaultFolder",v);
        end

        function v = get.ImageFormat(obj)
        %GET.IMAGEFORMAT Return the stored ImageFormat setting.

            v = obj.ImageFormat_;
        end

        function set.ImageFormat(obj,v)
        %SET.IMAGEFORMAT Validate, store, and notify a IO setting change.

            obj.setValue("ImageFormat",v);
        end

        function v = get.TableFormat(obj)
        %GET.TABLEFORMAT Return the stored TableFormat setting.

            v = obj.TableFormat_;
        end

        function set.TableFormat(obj,v)
        %SET.TABLEFORMAT Validate, store, and notify a IO setting change.

            obj.setValue("TableFormat",v);
        end

        function S = toStruct(obj)
        %TOSTRUCT Serialize values without listeners or graphics objects.

            % Plain settings snapshot containing values only, without listeners.
            S = struct('DefaultFolder',obj.DefaultFolder, ...
                'ImageFormat',obj.ImageFormat, ...
                'TableFormat',obj.TableFormat);
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
                ev = oops.config.ChangeEvent("IO",name,old,value);
                notify(obj,'IOChanged',ev);
                notify(obj,'Changed',ev);
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end
end
