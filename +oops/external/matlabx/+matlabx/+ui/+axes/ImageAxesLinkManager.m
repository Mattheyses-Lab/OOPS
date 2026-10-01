% matlabx - MATLAB utilities for app building, image display, and analysis.
% Copyright (C) 2026 William Dean
%
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the Free
% Software Foundation; either version 2 of the License, or (at your option)
% any later version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, see <https://www.gnu.org/licenses/>.

classdef ImageAxesLinkManager
%IMAGEAXESLINKMANAGER Link-group wiring and synchronization for ImageAxes.
%
%   ImageAxes exposes the public link API: addLink(), removeLinks(), and the
%   observable properties themselves. This collaborator owns the mechanics behind
%   that API:
%
%       - storing each axes' peer list
%       - creating PostSet listeners for linked properties
%       - propagating a changed property to peer axes
%       - temporarily disabling listeners to avoid recursive propagation
%       - reconciling linked state after ImageData resets display state
%
%   A "link group" is symmetric. Every axes stores all other axes in the group
%   as linkedAxes, so any axes can originate a property change and push that
%   value to the rest of the group.

    methods (Static)
        function add(source, links, props)
        %ADD Link selected properties across source and peer axes.

            % Keep the current policy simple: an ImageAxes can belong to one link
            % group at a time. API changes can relax this later if needed.
            if source.hasLinks
                error("matlabx:ui:axes:ImageAxes:UnableToLink", "Axes is already linked");
            end

            if isempty(links) || isempty(props)
                return
            end

            % The source axes is wired first and acts as the initial source of truth.
            source.linkedAxes = links;
            source.linkedProps = props;
            source.LinkListener = addlistener(source, props, 'PostSet', @(src,evt) source.syncPeersToSelf(src,evt));
            source.hasLinks = true;

            for i = 1:numel(links)
                % Each peer gets every other axes except itself. This makes the link
                % group symmetric rather than source/target-only.
                if i == 1
                    peerLinks = [source, links(2:end)];
                else
                    peerLinks = [links(1:i-1), source, links(i+1:end)];
                end

                peer = links(i);
                peer.linkedAxes = peerLinks;
                peer.linkedProps = props;
                peer.LinkListener = addlistener(peer, props, 'PostSet', @(src,evt) peer.syncPeersToSelf(src,evt));
                peer.hasLinks = true;
            end

            % Establish a shared state immediately. The source axes is the initial
            % source of truth, matching the previous inline ImageAxes behavior.
            for i = 1:numel(links)
                matlabx.ui.axes.ImageAxesLinkManager.syncFromSource(links(i), source, props);
            end
        end

        function remove(host)
        %REMOVE Disconnect every axes in host's current link group.

            % removeLinks() is intentionally group-wide: calling it from any linked
            % axes clears listeners and metadata on every peer.
            if ~host.hasLinks
                return
            end

            peers = host.linkedAxes;

            for i = 1:numel(peers)
                matlabx.ui.axes.ImageAxesLinkManager.clearHost(peers(i));
            end

            matlabx.ui.axes.ImageAxesLinkManager.clearHost(host);
        end

        function syncPeersToSource(source, evt)
        %SYNCPEERSTOSOURCE Propagate one linked property from source to peers.

            % PostSet events identify the property that just changed.
            propName = evt.Source.Name;

            for i = 1:numel(source.linkedAxes)
                target = source.linkedAxes(i);
                if isempty(target) || ~isvalid(target)
                    continue
                end

                % Disable target listeners while assigning the linked value. Without
                % this, target's PostSet listener would echo the assignment back to
                % the rest of the group and create recursive chatter.
                [~, listenerWasEnabled] = ...
                    matlabx.ui.axes.ImageAxesLinkManager.disableValidLinkListeners(target);
                cleanupListener = onCleanup( ...
                    @() matlabx.ui.axes.ImageAxesLinkManager.restoreLinkListenerState(target, listenerWasEnabled));

                % Component display properties need overlap-safe copying when linked
                % axes have different component counts.
                value = matlabx.ui.axes.ImageAxesLinkManager.getLinkedValue(source, propName, target);
                target.(propName) = value;

                % Restore immediately on success; onCleanup still protects the error
                % path.
                delete(cleanupListener);
                matlabx.ui.axes.ImageAxesLinkManager.restoreLinkListenerState(target, listenerWasEnabled);
            end
        end

        function syncFromFirstPeer(host)
        %SYNCFROMFIRSTPEER Re-apply linked state from the first valid peer.

            % ImageData replacement rebuilds local view/display state. This method
            % lets ImageAxes pull linked values back from an existing peer before the
            % final render.
            if ~host.hasLinks || isempty(host.linkedAxes) || isempty(host.linkedProps)
                return
            end

            for i = 1:numel(host.linkedAxes)
                source = host.linkedAxes(i);
                if ~isempty(source) && isvalid(source)
                    matlabx.ui.axes.ImageAxesLinkManager.syncFromSource(host, source, host.linkedProps);
                    return
                end
            end
        end

        function syncFromSource(target, source, props)
        %SYNCFROMSOURCE Pull linked property values from source into target.

            if isempty(source) || ~isvalid(source) || isempty(props)
                return
            end

            % This is the pull-side equivalent of syncPeersToSource: assignments
            % should not trigger outbound link propagation from target.
            [~, listenerWasEnabled] = ...
                matlabx.ui.axes.ImageAxesLinkManager.disableValidLinkListeners(target);
            cleanupListener = onCleanup( ...
                @() matlabx.ui.axes.ImageAxesLinkManager.restoreLinkListenerState(target, listenerWasEnabled));

            for k = 1:numel(props)
                propName = props{k};
                value = matlabx.ui.axes.ImageAxesLinkManager.getLinkedValue(source, propName, target);
                target.(propName) = value;
            end

            delete(cleanupListener);
            matlabx.ui.axes.ImageAxesLinkManager.restoreLinkListenerState(target, listenerWasEnabled);
        end

        function value = getLinkedValue(source, propName, target)
        %GETLINKEDVALUE Return a source value safe to assign to target.

            value = source.(propName);

            switch propName
                case {'ComponentColormaps','ComponentCLims','ComponentColors'}
                    % These properties are full per-component cell arrays. If axes
                    % have different component counts, copy the shared prefix and
                    % preserve target entries beyond that range.
                    targetValue = target.(propName);
                    n = min(numel(value), numel(targetValue));

                    if n == 0
                        value = targetValue;
                        return
                    end

                    targetValue(1:n) = value(1:n);
                    value = targetValue;
            end
        end
    end

    methods (Static, Access=private)
        function clearHost(host)
        %CLEARHOST Remove link metadata and listeners from one axes.
            % Delete valid listeners before clearing metadata to avoid orphaned
            % callbacks retaining host references.
            if isempty(host) || ~isvalid(host)
                return
            end

            if ~isempty(host.LinkListener)
                delete(host.LinkListener(isvalid(host.LinkListener)));
            end

            host.linkedAxes = [];
            host.linkedProps = {};
            host.LinkListener = event.listener.empty;
            host.hasLinks = false;
        end

        function [listeners, wasEnabled] = disableValidLinkListeners(host)
        %DISABLEVALIDLINKLISTENERS Temporarily disable valid link listeners.
            % Return prior Enabled states so nested/initial sync can restore the
            % exact listener state instead of blindly enabling everything.
            listeners = event.listener.empty;
            wasEnabled = false(1,0);

            if isempty(host.LinkListener)
                return
            end

            listeners = host.LinkListener(isvalid(host.LinkListener));
            wasEnabled = false(1, numel(listeners));

            for ii = 1:numel(listeners)
                wasEnabled(ii) = listeners(ii).Enabled;
                listeners(ii).Enabled = false;
            end
        end

        function restoreLinkListenerState(host, wasEnabled)
        %RESTORELINKLISTENERSTATE Restore previously captured listener states.
            % Restore only the listeners that still exist. Handles may disappear if
            % the axes or link group is deleted during a callback.
            if isempty(host) || ~isvalid(host) || isempty(host.LinkListener)
                return
            end

            listeners = host.LinkListener(isvalid(host.LinkListener));
            n = min(numel(listeners), numel(wasEnabled));

            for ii = 1:n
                listeners(ii).Enabled = wasEnabled(ii);
            end
        end
    end

end
