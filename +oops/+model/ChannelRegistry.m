% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef ChannelRegistry < handle
%CHANNELREGISTRY Own ordered project-wide semantic channel definitions.

    events
        ChannelsChanged
    end

    properties (SetAccess=private)
        Channels (:,1) oops.model.ChannelDefinition = ...
            oops.model.ChannelDefinition.empty(0,1)
    end

    methods

        function delete(obj)
        %DELETE Release the registry-owned channel definitions.

            for k = 1:numel(obj)
                delete(obj(k).Channels);
            end
        end

        function channel = add(obj,name,color)
        %ADD Append a uniquely named semantic channel definition.

            arguments
                obj
                name (1,1) string
                color (1,3) double {mustBeFinite,mustBeInRange(color,0,1)} = obj.nextColor()
            end

            name = strtrim(name);

            if any(strcmpi(name,string({obj.Channels.Name})))
                error('oops:model:DuplicateChannelName', ...
                    'A channel named "%s" already exists.',name);
            end

            channel = oops.model.ChannelDefinition(name,color);
            obj.Channels(end+1,1) = channel;
            notify(obj,'ChannelsChanged');
        end

        function channel = findByID(obj,id)
        %FINDBYID Resolve a semantic channel by its stable project ID.

            ids = string({obj.Channels.ID});
            index = find(ids == string(id),1);

            if isempty(index)
                channel = oops.model.ChannelDefinition.empty(0,1);
            else
                channel = obj.Channels(index);
            end
        end

        function channel = findByName(obj,name)
        %FINDBYNAME Resolve a semantic channel by case-insensitive display name.

            names = string({obj.Channels.Name});
            index = find(strcmpi(strtrim(string(name)),names),1);

            if isempty(index)
                channel = oops.model.ChannelDefinition.empty(0,1);
            else
                channel = obj.Channels(index);
            end
        end

        function channel = findOrAdd(obj,name,color)
        %FINDORADD Reuse a semantic name or append its first colored definition.

            arguments
                obj
                name (1,1) string
                color (1,3) double {mustBeFinite,mustBeInRange(color,0,1)} = obj.nextColor()
            end

            channel = obj.findByName(name);

            if isempty(channel)
                channel = obj.add(name,color);
            end
        end

        function edit(obj,id,name,color)
        %EDIT Update a channel after validating its project-wide name.

            channel = obj.findByID(id);

            if isempty(channel)
                error('oops:model:UnknownChannel','Unknown channel ID: %s',id);
            end

            ids = string({obj.Channels.ID});
            other = obj.Channels(ids ~= channel.ID);

            if any(strcmpi(strtrim(name),string({other.Name})))
                error('oops:model:DuplicateChannelName', ...
                    'A channel named "%s" already exists.',name);
            end

            channel.setProperties(name,color);
            notify(obj,'ChannelsChanged');
        end

        function remove(obj,id)
        %REMOVE Delete an unreferenced channel definition from the registry.

            index = find(string({obj.Channels.ID}) == string(id),1);

            if isempty(index)
                error('oops:model:UnknownChannel','Unknown channel ID: %s',id);
            end

            channel = obj.Channels(index);
            obj.Channels(index) = [];
            delete(channel);
            notify(obj,'ChannelsChanged');
        end

        function move(obj,id,offset)
        %MOVE Change one channel's persistent registry order.

            index = find(string({obj.Channels.ID}) == string(id),1);

            if isempty(index)
                error('oops:model:UnknownChannel','Unknown channel ID: %s',id);
            end

            target = index+offset;

            if target < 1 || target > numel(obj.Channels) || target == index
                return;
            end

            obj.Channels([index target]) = obj.Channels([target index]);
            notify(obj,'ChannelsChanged');
        end

        function S = toStruct(obj)
        %TOSTRUCT Capture ordered channel definitions for project persistence.

            S = arrayfun(@(channel) channel.toStruct(),obj.Channels);
        end

    end

    methods (Static)

        function obj = fromStruct(S)
        %FROMSTRUCT Restore an ordered registry from serialized definitions.

            obj = oops.model.ChannelRegistry();

            for k = 1:numel(S)
                channel = oops.model.ChannelDefinition.fromStruct(S(k));

                if ~isempty(obj.findByID(channel.ID)) || ...
                        ~isempty(obj.findByName(channel.Name))
                    error('oops:model:DuplicateChannelDefinition', ...
                        'Channel IDs and names must be unique.');
                end

                obj.Channels(end+1,1) = channel;
            end
        end

    end

    methods (Access=private)

        function color = nextColor(obj)
        %NEXTCOLOR Select the next MATLAB axes color without requiring uniqueness.

            order = get(groot,'defaultAxesColorOrder');
            index = mod(numel(obj.Channels),size(order,1))+1;
            color = order(index,:);
        end

    end

end
