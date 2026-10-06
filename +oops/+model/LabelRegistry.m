% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef LabelRegistry < handle
%LABELREGISTRY Own ordered project labels and resolve them by ID or hotkey.

    properties (SetAccess=private)
        ActiveLabelID (1,1) string = ""
    end

    properties (Access=private)
        LabelsByID dictionary
        IDsByHotkey dictionary
        Order (1,:) string = string.empty(1,0)
    end

    events
        LabelsChanged
        ActiveChanged
    end

    methods

        function obj = LabelRegistry()
        %LABELREGISTRY Create an empty registry with typed lookup dictionaries.

            obj.LabelsByID = dictionary( ...
                string.empty(1,0),oops.model.ObjectLabel.empty(1,0));
            obj.IDsByHotkey = dictionary( ...
                string.empty(1,0),string.empty(1,0));
        end

        function ids = ids(obj)
        %IDS Return label IDs in their user-facing order.

            ids = obj.Order;
        end

        function values = labels(obj)
        %LABELS Return label objects in their user-facing order.

            if isempty(obj.Order)
                values = oops.model.ObjectLabel.empty(1,0);
            else
                values = obj.LabelsByID(obj.Order);
            end
        end

        function keys = hotkeys(obj)
        %HOTKEYS Return nonempty shortcuts in label order.

            values = obj.labels();
            keys = [values.Hotkey];
            keys = keys(strlength(keys) > 0);
        end

        function label = getByID(obj,id)
        %GETBYID Resolve one stable label ID, returning empty when unknown.

            id = string(id);

            if strlength(id) == 0 || ~isKey(obj.LabelsByID,id)
                label = oops.model.ObjectLabel.empty(0,1);
            else
                label = obj.LabelsByID(id);
            end
        end

        function label = getByHotkey(obj,key)
        %GETBYHOTKEY Resolve a case-insensitive keyboard shortcut.

            key = lower(string(key));

            if strlength(key) == 0 || ~isKey(obj.IDsByHotkey,key)
                label = oops.model.ObjectLabel.empty(0,1);
            else
                label = obj.getByID(obj.IDsByHotkey(key));
            end
        end

        function label = active(obj)
        %ACTIVE Resolve the active label bookmark.

            label = obj.getByID(obj.ActiveLabelID);
        end

        function id = add(obj,name,opts)
        %ADD Register a label after enforcing unique names, IDs, and hotkeys.

            arguments
                obj
                name (1,1) string
                opts.ID (1,1) string = ""
                opts.Hotkey (1,1) string = ""
                opts.Color (1,3) double = [1 1 1]
                opts.CreatedAt (1,1) datetime = datetime('now')
                opts.MakeActive (1,1) logical = false
            end

            label = oops.model.ObjectLabel(name, ...
                ID=opts.ID,Hotkey=opts.Hotkey,Color=opts.Color,CreatedAt=opts.CreatedAt);
            obj.validateIdentity(label.ID,label.Name,label.Hotkey,"");

            obj.LabelsByID(label.ID) = label;
            obj.Order(end+1) = label.ID;

            if label.hasHotkey()
                obj.IDsByHotkey(label.Hotkey) = label.ID;
            end

            notify(obj,'LabelsChanged');

            if opts.MakeActive
                obj.setActiveByID(label.ID);
            end

            id = label.ID;
        end

        function newID = edit(obj,id,opts)
        %EDIT Update a label and return its current, possibly changed, ID.

            arguments
                obj
                id (1,1) string
                opts.Name string = string.empty()
                opts.ID string = string.empty()
                opts.Hotkey string = string.empty()
                opts.Color double = []
            end

            id = string(id);
            label = obj.getByID(id);

            if isempty(label)
                error('oops:model:UnknownLabel','Unknown object label ID: %s',id);
            end

            name = label.Name;
            newID = label.ID;
            hotkey = label.Hotkey;
            color = label.Color;

            if ~isempty(opts.Name)
                name = strtrim(string(opts.Name));
            end

            if ~isempty(opts.ID)
                newID = strtrim(string(opts.ID));
            end

            if ~isempty(opts.Hotkey)
                hotkey = lower(strtrim(string(opts.Hotkey)));
            end

            if ~isempty(opts.Color)
                validateattributes(opts.Color,{'numeric'},{'size',[1 3],'real','finite','>=',0,'<=',1});
                color = double(opts.Color);
            end

            if id == "unlabeled" && newID ~= id
                error('oops:model:ReservedLabelID', ...
                    'The default unlabeled label must retain the ID "unlabeled".');
            end

            obj.validateIdentity(newID,name,hotkey,id);

            if label.hasHotkey()
                remove(obj.IDsByHotkey,label.Hotkey);
            end

            % Re-key the registry and ordered list before exposing the new identity.
            if newID ~= id
                remove(obj.LabelsByID,id);
                obj.Order(obj.Order == id) = newID;
            end

            label.update(newID,name,hotkey,color);
            obj.LabelsByID(newID) = label;

            if label.hasHotkey()
                obj.IDsByHotkey(label.Hotkey) = label.ID;
            end

            if obj.ActiveLabelID == id && newID ~= id
                obj.ActiveLabelID = newID;
                notify(obj,'ActiveChanged');
            end

            notify(obj,'LabelsChanged');
        end

        function remove(obj,id)
        %REMOVE Unregister a user label after its object references are migrated.

            id = string(id);
            label = obj.getByID(id);

            if isempty(label)
                error('oops:model:UnknownLabel','Unknown object label ID: %s',id);
            end

            if id == "unlabeled"
                error('oops:model:ReservedLabelID', ...
                    'The default unlabeled label cannot be deleted.');
            end

            if label.hasHotkey()
                remove(obj.IDsByHotkey,label.Hotkey);
            end

            remove(obj.LabelsByID,id);
            obj.Order(obj.Order == id) = [];

            if obj.ActiveLabelID == id
                obj.ActiveLabelID = "unlabeled";
                notify(obj,'ActiveChanged');
            end

            notify(obj,'LabelsChanged');
        end

        function setActiveByID(obj,id)
        %SETACTIVEBYID Store the active label independently of object selection.

            id = string(id);

            if strlength(id) > 0 && ~isKey(obj.LabelsByID,id)
                error('oops:model:UnknownLabel','Unknown object label ID: %s',id);
            end

            if obj.ActiveLabelID == id
                return;
            end

            obj.ActiveLabelID = id;
            notify(obj,'ActiveChanged');
        end

        function S = toStruct(obj)
        %TOSTRUCT Serialize label values without handles or listeners.

            values = obj.labels();
            entries = repmat(struct( ...
                'ID',"",'Name',"",'Hotkey',"",'Color',[1 1 1], ...
                'CreatedAt',datetime.empty()),1,numel(values));

            for k = 1:numel(values)
                entries(k).ID = values(k).ID;
                entries(k).Name = values(k).Name;
                entries(k).Hotkey = values(k).Hotkey;
                entries(k).Color = values(k).Color;
                entries(k).CreatedAt = values(k).CreatedAt;
            end

            S = struct('ActiveLabelID',obj.ActiveLabelID, ...
                'Order',obj.Order,'Labels',entries);
        end

    end

    methods (Access=private)

        function validateIdentity(obj,id,name,hotkey,ownerID)
        %VALIDATEIDENTITY Reject ambiguous names, IDs, and keyboard shortcuts.

            id = strtrim(string(id));
            name = strtrim(string(name));
            hotkey = lower(strtrim(string(hotkey)));

            if strlength(name) == 0
                error('oops:model:InvalidLabelName','Object label names must be nonempty.');
            end

            if strlength(id) == 0
                error('oops:model:InvalidLabelID','Object label IDs must be nonempty.');
            end

            % Case-insensitive comparisons prevent identities that look identical in UI.
            otherIDs = obj.Order(lower(obj.Order) ~= lower(ownerID));

            if any(lower(otherIDs) == lower(id))
                error('oops:model:DuplicateLabelID','Object label ID already exists: %s',id);
            end

            otherLabels = obj.labels();

            if strlength(ownerID) > 0
                otherLabels = otherLabels(lower([otherLabels.ID]) ~= lower(ownerID));
            end

            if ~isempty(otherLabels) && any(lower(strtrim([otherLabels.Name])) == lower(name))
                error('oops:model:DuplicateLabelName', ...
                    'Object label name already exists: %s',name);
            end

            if strlength(hotkey) > 0 && isKey(obj.IDsByHotkey,hotkey) && ...
                    obj.IDsByHotkey(hotkey) ~= ownerID
                error('oops:model:DuplicateLabelHotkey', ...
                    'Object label hotkey is already in use: %s',hotkey);
            end

            if strlength(hotkey) > 1 || ...
                    (strlength(hotkey) == 1 && ~isstrprop(char(hotkey),'alphanum'))
                error('oops:model:InvalidLabelHotkey', ...
                    'Object label hotkeys must be one alphanumeric character.');
            end
        end

    end

    methods (Static)

        function obj = default()
        %DEFAULT Create the initial OOPS label set and active label.

            obj = oops.model.LabelRegistry();
            obj.add("Unlabeled",ID="unlabeled",Hotkey="u",Color=[0.7 0.7 0.7]);
            obj.setActiveByID("unlabeled");
        end

        function obj = fromStruct(S)
        %FROMSTRUCT Restore serialized labels through validated registry APIs.

            obj = oops.model.LabelRegistry();

            if isfield(S,'Labels')

                for k = 1:numel(S.Labels)
                    entry = S.Labels(k);
                    createdAt = datetime('now');

                    if isfield(entry,'CreatedAt') && ~isempty(entry.CreatedAt)
                        createdAt = entry.CreatedAt;
                    end

                    obj.add(string(entry.Name), ...
                        ID=string(entry.ID),Hotkey=string(entry.Hotkey), ...
                        Color=double(entry.Color),CreatedAt=createdAt);
                end

            end

            if isfield(S,'Order') && ~isempty(S.Order)
                obj.Order = string(S.Order);
            end

            if isfield(S,'ActiveLabelID')
                obj.setActiveByID(string(S.ActiveLabelID));
            end
        end

    end

end
