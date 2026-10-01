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

classdef ImageAxesHotkeyRegistry < handle
%IMAGEAXESHOTKEYREGISTRY Small keypress command registry for ImageAxes.
%
%   The registry maps normalized HubEvent.Hotkey strings to callbacks. A
%   "hotkey" is the canonical string produced by matlabx.keyboard.normalize,
%   for example "z", "escape", or "shift+meta+z".
%
%   ImageAxes owns the event dispatch sequence. Tools and host features
%   contribute bindings when they are installed or configured, and the registry
%   chooses the highest-priority callback for the keypress. Owner tracking lets
%   ImageAxes remove every binding contributed by a tool when that tool is
%   uninstalled or deleted.
%
%   This is deliberately not a general keyboard framework. It is a compact
%   lookup table for keypress commands scoped to one ImageAxes instance.

    properties (Access=private)
        Keys (1,:) string = string.empty(1,0)
        Owners (1,:) cell = {}
        Callbacks (1,:) cell = {}
        Descriptions (1,:) string = string.empty(1,0)
        Priorities (1,:) double = []
    end

    methods
        function add(obj, key, callback, opts)
        %ADD Register or replace one hotkey binding.
        %
        %   If the same owner registers the same key again, its callback and
        %   metadata are updated in place. If a different owner registers the same
        %   key, both bindings are retained and dispatch uses Priority to choose.
            arguments
                obj
                key
                callback
                opts.Owner = []
                opts.Description (1,1) string = ""
                opts.Priority (1,1) double = 0
            end

            key = obj.canonicalizeHotkeyString(key);

            % Registration accepts strings from tool authors, so validate here
            % even though HubEvent hotkeys are already normalized before dispatch.
            if strlength(key) == 0
                error('ImageAxesHotkeyRegistry:InvalidHotkey', ...
                    'Hotkey must be a nonempty string scalar.')
            end

            if ~(isa(callback, 'function_handle') && isscalar(callback))
                error('ImageAxesHotkeyRegistry:InvalidCallback', ...
                    'Hotkey callback must be a scalar function handle.')
            end

            % Multiple tools may intentionally use the same key later. Track whether
            % this is an owner refresh versus a competing binding.
            existing = find(obj.Keys == key);
            sameOwner = false(size(existing));
            for i = 1:numel(existing)
                sameOwner(i) = obj.ownersMatch(obj.Owners{existing(i)}, opts.Owner);
            end

            % Re-registering from the same owner should be idempotent. This is useful
            % if a tool is reconfigured without uninstalling first.
            if any(sameOwner)
                idx = existing(find(sameOwner, 1, 'first'));
                obj.Callbacks{idx} = callback;
                obj.Descriptions(idx) = opts.Description;
                obj.Priorities(idx) = opts.Priority;
                return
            end

            % Do not error on collisions yet; a future user-facing API can expose
            % conflict inspection/resolution. For now priority decides.
            if ~isempty(existing)
                warning('ImageAxesHotkeyRegistry:DuplicateHotkey', ...
                    'Hotkey "%s" is already registered; highest priority binding will run.', key)
            end

            obj.Keys(end+1) = key;
            obj.Owners{end+1} = opts.Owner;
            obj.Callbacks{end+1} = callback;
            obj.Descriptions(end+1) = opts.Description;
            obj.Priorities(end+1) = opts.Priority;
        end

        function removeOwner(obj, owner)
        %REMOVEOWNER Remove every binding contributed by a given owner.
        %
        %   The owner is usually an AxesTool handle. Owner-scoped cleanup prevents
        %   a tool from leaving behind a callback after it is uninstalled.
            if isempty(obj.Keys)
                return
            end

            remove = false(size(obj.Keys));
            for i = 1:numel(obj.Keys)
                remove(i) = obj.ownersMatch(obj.Owners{i}, owner);
            end

            obj.removeByMask(remove);
        end

        function tf = dispatch(obj, E)
        %DISPATCH Run the highest-priority callback matching a HubEvent hotkey.
        %
        %   Returns true when a matching callback was invoked. The callback decides
        %   whether to call E.stop() or otherwise mark the event.
            tf = false;

            % Only keypress events participate. Key release and mouse chords remain
            % ordinary FigureEventHub events for now.
            if isempty(obj.Keys) || ~E.isKeyPressEvent() || strlength(E.Hotkey) == 0
                return
            end

            % HubEvent.Hotkey is already normalized; this canonicalization is a
            % defensive lowercase/string check for direct/manual dispatch paths.
            key = obj.canonicalizeHotkeyString(E.Hotkey);
            idx = find(obj.Keys == key, 1);

            if isempty(idx)
                return
            end

            % Prune bindings from deleted handle owners just before dispatch. This
            % keeps stale callbacks from surviving unusual deletion paths.
            obj.removeInvalidOwners();
            idx = find(obj.Keys == key);

            if isempty(idx)
                return
            end

            % If several bindings share a key, choose the highest priority. Ties use
            % MATLAB's first max, i.e. earliest matching registration.
            [~, best] = max(obj.Priorities(idx));
            callback = obj.Callbacks{idx(best)};
            callback(E);
            tf = true;
        end

        function S = entries(obj)
        %ENTRIES Return a lightweight summary of registered bindings.
        %
        %   This is primarily for debugging/introspection; callbacks and owners are
        %   intentionally omitted from the display struct.
            S = struct( ...
                'Key', cellstr(obj.Keys), ...
                'Description', cellstr(obj.Descriptions), ...
                'Priority', num2cell(obj.Priorities));
        end
    end

    methods (Access=private)
        function removeInvalidOwners(obj)
        %REMOVEINVALIDOWNERS Remove bindings whose owner is a deleted handle.
            if isempty(obj.Keys)
                return
            end

            remove = false(size(obj.Keys));
            for i = 1:numel(obj.Keys)
                remove(i) = ~obj.ownerIsValid(obj.Owners{i});
            end

            obj.removeByMask(remove);
        end

        function removeByMask(obj, remove)
        %REMOVEBYMASK Delete bindings selected by a logical mask.
            % Apply the same logical deletion mask to every parallel storage array.
            if ~any(remove)
                return
            end

            keep = ~remove;
            obj.Keys = obj.Keys(keep);
            obj.Owners = obj.Owners(keep);
            obj.Callbacks = obj.Callbacks(keep);
            obj.Descriptions = obj.Descriptions(keep);
            obj.Priorities = obj.Priorities(keep);
        end
    end

    methods (Static, Access=private)
        function key = canonicalizeHotkeyString(key)
        %CANONICALIZEHOTKEYSTRING Normalize a declared hotkey string.
            % Canonicalize a declared hotkey string, not raw key event fields.
            key = lower(string(key));

            if ~isscalar(key)
                error('ImageAxesHotkeyRegistry:InvalidHotkey', ...
                    'Hotkey must be a string scalar.')
            end
        end

        function tf = ownerIsValid(owner)
        %OWNERISVALID Return false for deleted handle owners.
            % Empty/non-handle owners are treated as durable registry entries.
            tf = true;

            if isempty(owner)
                return
            end

            try
                if isa(owner, 'handle')
                    tf = isvalid(owner);
                end
            catch
                tf = true;
            end
        end

        function tf = ownersMatch(a, b)
        %OWNERSMATCH Return true when two registry owners are equal.
            % Handle equality can throw for some deleted or unusual objects.
            try
                tf = isequal(a, b);
            catch
                tf = false;
            end
        end
    end

end
