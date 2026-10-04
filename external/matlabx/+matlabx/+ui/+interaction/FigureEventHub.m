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

classdef FigureEventHub < handle
%FIGUREEVENTHUB Route figure-level UI events to registered interaction handlers.
%
%   HUB = matlabx.ui.interaction.FigureEventHub.ensure(FIG) installs, or
%   returns, one shared event hub for a uifigure. The hub owns the figure's
%   low-level callbacks and routes normalized HubEvent payloads to registered
%   objects such as ImageAxes.
%
%   The hub has two audiences:
%     1. Registrants claim events by implementing matches/onDown/onMove/etc.
%     2. Passive listeners observe selected event kinds without claiming them.
%
%   This lets components and tools share one figure safely instead of each
%   overwriting WindowButtonDownFcn, KeyPressFcn, and similar callbacks.
%
% Modifier and menubar focus note
%
%   On some MATLAB/platform combinations, pressing and releasing alt/option
%   can focus the figure menubar. Once the menubar owns keyboard focus,
%   later modifier-release events may not reach the hub; for example,
%   alt+shift followed by releasing alt first can leave the hub believing
%   shift is still down. To preserve alt as a usable tool modifier, the hub
%   temporarily disables top-level figure menus while alt/option is held and
%   restores their exact previous Enable states on alt/option release.
%
% Notes/Definitions
%
% Registrant: object registered with the hub (e.g., axes.ImageAxes)
%   Each registrant registers itself with the hub at startup and must implement
%   matches(E), which returns true if the registrant should claim the event.
%
% Registry entry: stored info about a registrant (id, obj, priority, CaptureDuringDrag)
%   id (stable numeric ID), obj (the registrant handle), priority (bigger wins), CaptureDuringDrag (logical)
%
% Priority: resolves overlaps—higher priority registrants get first dibs when multiple "match"
%
% Claimant: the registrant that currently matches the pointer/target under hub evaluation 
%   (i.e. the registrant that "claims" ownership of the current event)
% 
% Capture: when active, all events go exclusively to one registrant (the captor) until mouse-up
%   CaptureId: the stable ID of the current captor (or NaN if none)
%
% Hover: the registrant that currently "claims" the pointer (according to matches)
%   HoverId: the stable ID of the current hover claimant (or NaN if none)
% 
% Captor: the registrant currently holding capture
% 
% tgt: graphics obj under cursor (hittest(Fig) result)
% 
% kind: the event kind string the hub uses to sort events:
%   'Move'|'Down'|'Up'|'Scroll'|'KeyPress'|'KeyRelease'|'Enter'|'Leave'
%   The first six correspond to figure callbacks. Enter and Leave are
%   synthetic hover-transition events generated when the hover claimant changes.
%
% evt: the MATLAB event struct passed from the figure callback (e.g., WindowButtonDownFcn arg, etc.)

    properties (Access=private)
        Fig matlab.ui.Figure

        % Registrants, sorted by Priority descending
        Registry = struct( ...
            'obj', {}, ...
            'id', {}, ...
            'Priority', {}, ...
            'CaptureDuringDrag', {});

        NextID double = 1           % ID to assign to the next registrant
        HoverID double = NaN        % ID of the current hover claimant
        CaptureID double = NaN      % ID of the registrant holding capture

        ModifierState (1,:) string = string.empty(1,0)
        LastKey (1,1) string = ""
        LastHotkey (1,1) string = ""
        LastKeyTimestamp datetime = NaT
        ShortcutModifierStateMaxAge duration = seconds(1)
        ShortcutModifierStateTimestamp datetime = NaT
        AltDisabledMenus = matlab.ui.container.Menu.empty(1,0)
        AltDisabledMenuEnableState (1,:) string = string.empty(1,0)

        % Extra listeners keyed by event kind.
        ListenerRegistry struct = struct( ...
            'Down',       struct('id', {}, 'Fcn', {}, 'Priority', {}), ...
            'Move',       struct('id', {}, 'Fcn', {}, 'Priority', {}), ...
            'Up',         struct('id', {}, 'Fcn', {}, 'Priority', {}), ...
            'Scroll',     struct('id', {}, 'Fcn', {}, 'Priority', {}), ...
            'KeyPress',   struct('id', {}, 'Fcn', {}, 'Priority', {}), ...
            'KeyRelease', struct('id', {}, 'Fcn', {}, 'Priority', {}), ...
            'Enter',      struct('id', {}, 'Fcn', {}, 'Priority', {}), ...
            'Leave',      struct('id', {}, 'Fcn', {}, 'Priority', {}))

        NextListenerID double = 1
    end

    methods (Static)

        function hub = ensure(fig)
        %ENSURE Return the installed hub for a figure, creating one if needed.
            hub = getappdata(fig, 'FigureEventHub');
            if isempty(hub) || ~isvalid(hub)
                hub = matlabx.ui.interaction.FigureEventHub(fig);
                setappdata(fig, 'FigureEventHub', hub);
            end
        end

    end

    methods (Access=private)

        function obj = FigureEventHub(fig)
        %FIGUREEVENTHUB Construct and install callback dispatchers.
            obj.Fig = fig;

            % Preserve existing callback functions as low-priority listeners
            % before the hub takes ownership of the figure callback slots.
            obj.captureExistingCallback('WindowButtonDownFcn',   'Down');
            obj.captureExistingCallback('WindowButtonMotionFcn', 'Move');
            obj.captureExistingCallback('WindowButtonUpFcn',     'Up');
            obj.captureExistingCallback('WindowScrollWheelFcn',  'Scroll');
            obj.captureExistingCallback('KeyPressFcn',           'KeyPress');
            obj.captureExistingCallback('KeyReleaseFcn',         'KeyRelease');

            % Install hub dispatchers
            fig.WindowButtonDownFcn   = @(~,evt) obj.route('Down', evt);
            fig.WindowButtonMotionFcn = @(~,evt) obj.route('Move', evt);
            fig.WindowButtonUpFcn     = @(~,evt) obj.route('Up', evt);
            fig.WindowScrollWheelFcn  = @(~,evt) obj.route('Scroll', evt);
            fig.KeyPressFcn           = @(~,evt) obj.route('KeyPress', evt);
            fig.KeyReleaseFcn         = @(~,evt) obj.route('KeyRelease', evt);
        end

        function captureExistingCallback(obj, propName, kind)
        %CAPTUREEXISTINGCALLBACK Preserve a pre-existing figure callback.
            existing = obj.Fig.(propName);
            if ~isempty(existing)
                obj.addListener(kind, existing, 'Priority', -inf);
            end
        end

    end

    methods

        function id = register(obj, h, varargin)
        %REGISTER Add an event-claiming object to the hub registry.
        %
        %   ID = HUB.register(H) registers H with default priority.
        %   ID = HUB.register(H,'Priority',P,'CaptureDuringDrag',TF)
        %   controls overlap resolution and drag capture.

            p = inputParser;
            p.addParameter('Priority', 0, @(x) isnumeric(x) && isscalar(x));
            p.addParameter('CaptureDuringDrag', false, @(x) islogical(x) && isscalar(x));
            p.parse(varargin{:});

            % Registrants use a deliberately small protocol. Requiring the
            % methods at registration gives clearer errors than a later click.
            requiredMethods = obj.getRequiredMethods();
            for i = 1:numel(requiredMethods)
                if ~ismethod(h, requiredMethods{i})
                    error('FigureEventHub:MatchError', ...
                        'Registrant missing required method: %s', requiredMethods{i});
                end
            end

            % new entry struct
            entry.id = obj.NextID;
            entry.obj = h;
            entry.Priority = p.Results.Priority;
            entry.CaptureDuringDrag = p.Results.CaptureDuringDrag;

            % add to registry, sort by Priority descending
            obj.Registry(end+1) = entry;
            obj.sortRegistry();

            % ID to return to this registrant
            id = entry.id;

            % set ID for the next entry
            obj.NextID = obj.NextID + 1;
        end

        function unregister(obj, id)
        %UNREGISTER Remove a registrant and release any hover/capture state.
            if nargin < 2 || isempty(id) || ~isfinite(id)
                return
            end

            idx = obj.indexOfID(id);
            if isempty(idx)
                return
            end

            % release capture if necessary
            if ~isnan(obj.CaptureID) && obj.CaptureID == id
                obj.CaptureID = NaN;
            end

            % release hover if necessary, then fire onLeave()
            if ~isnan(obj.HoverID) && obj.HoverID == id
                tgt = hittest(obj.Fig);
                E = matlabx.ui.interaction.HubEvent(obj.Fig, tgt, 'Leave', [], ...
                    "ModifierState", obj.ModifierState, ...
                    "LastKey", obj.LastKey, ...
                    "LastHotkey", obj.LastHotkey, ...
                    "LastKeyTimestamp", obj.LastKeyTimestamp, ...
                    "Claimant", obj.Registry(idx).obj);
                obj.safeCall(obj.Registry(idx).obj, 'onLeave', E);
                obj.notifyListeners(E);
                obj.HoverID = NaN;
            end

            % remove from registry
            obj.Registry(idx) = [];
        end

        function id = addListener(obj, kind, fcn, varargin)
        %ADDLISTENER Add a passive listener for one supported event kind.
        %
        %   ID = HUB.addListener(KIND,FCN) calls FCN(E) after hub routing.
        %   Listeners observe events but do not participate in claiming,
        %   capture, or propagation.

            kind = validatestring(kind, obj.supportedKinds());

            p = inputParser;
            p.addParameter('Priority', 0, @(x) isnumeric(x) && isscalar(x));
            p.parse(varargin{:});

            if ~isa(fcn, 'function_handle')
                error('Listener must be a function handle.');
            end

            % new listener entry struct
            entry.id = obj.NextListenerID;
            entry.Fcn = fcn;
            entry.Priority = p.Results.Priority;

            % add to registry for this event kind, sort by Priority descending
            obj.ListenerRegistry.(kind)(end+1) = entry;
            obj.sortListeners(kind);

            % ID to return
            id = entry.id;

            % set ID for the next listener
            obj.NextListenerID = obj.NextListenerID + 1;
        end

        function removeListener(obj, kind, id)
        %REMOVELISTENER Remove a passive listener by kind and listener ID.
            kind = validatestring(kind, obj.supportedKinds());

            % get listener registry for this event kind
            L = obj.ListenerRegistry.(kind);
            if isempty(L)
                return
            end

            % find matching listener entry by ID
            idx = find([L.id] == id, 1, 'first');
            if isempty(idx)
                return
            end

            % remove entry, update registry
            L(idx) = [];
            obj.ListenerRegistry.(kind) = L;
        end

        function clearListeners(obj, kind)
        %CLEARLISTENERS Remove all passive listeners for one event kind.
            kind = validatestring(kind, obj.supportedKinds());
            obj.ListenerRegistry.(kind) = struct('id', {}, 'Fcn', {}, 'Priority', {});
        end

        function listRegistrants(obj)
        %LISTREGISTRANTS Print registered event claimants and priorities.
            for i = 1:numel(obj.Registry)
                entry = obj.Registry(i);
                fprintf('Entry %d: %s (Priority=%g, ID=%d)\n', ...
                    i, class(entry.obj), entry.Priority, entry.id);
            end
            fprintf('\n');
        end

        function listListeners(obj, kind)
        %LISTLISTENERS Print passive listeners for one event kind.
            kind = validatestring(kind, obj.supportedKinds());
            L = obj.ListenerRegistry.(kind);

            for i = 1:numel(L)
                fprintf('%s listener %d: Priority=%g, ID=%d\n', ...
                    kind, i, L(i).Priority, L(i).id);
            end
            fprintf('\n');
        end

    end

    methods (Access=private)

        function route(obj, kind, evt)
        %ROUTE Build a HubEvent and dispatch it to claimants/listeners.
            % Clean up stale handles before every route. This keeps deleted
            % components from trapping events without requiring manual teardown.
            obj.pruneInvalidRegistrants();
            obj.pruneInvalidListeners(kind);

            obj.updateKeyboardState(kind, evt);
            obj.expireStaleShortcutModifierState(kind);

            % hittest gives the graphics/UI object currently under the pointer.
            tgt = hittest(obj.Fig);
            E = matlabx.ui.interaction.HubEvent(obj.Fig, tgt, kind, evt, ...
                "ModifierState", obj.ModifierState, ...
                "LastKey", obj.LastKey, ...
                "LastHotkey", obj.LastHotkey, ...
                "LastKeyTimestamp", obj.LastKeyTimestamp);

            % If captured, route only to current captor until mouse up
            if ~isnan(obj.CaptureID)
                idx = obj.indexOfID(obj.CaptureID);

                if isempty(idx) 
                    obj.CaptureID = NaN;
                else % route to captor
                    e = obj.Registry(idx);
                    obj.call(e.obj, E);

                    if strcmp(kind, 'Up')
                        obj.CaptureID = NaN;   % release capture
                        obj.updateHover(E);    % recompute hover
                    end

                    obj.notifyListeners(E);
                    return
                end
            end

            obj.updateHover(E);

            % Dispatch to hover claimant
            if ~isnan(obj.HoverID)
                idx = obj.indexOfID(obj.HoverID);

                if ~isempty(idx)
                    % route to hover claimant
                    e = obj.Registry(idx);
                    obj.call(e.obj, E);
                    % hover claimaint claims capture on mouse down
                    if strcmp(kind, 'Down') && e.CaptureDuringDrag
                        obj.CaptureID = e.id;
                    end
                else
                    obj.HoverID = NaN;  % release hover
                end
            end
            % Notify chained listeners for this event kind
            obj.notifyListeners(E);
        end

        function updateHover(obj, E)
        %UPDATEHOVER Recompute the current hover claimant and emit transitions.
            claimantID = NaN;
            % Iterate in priority order. The first positive match owns hover.
            for k = 1:numel(obj.Registry)
                e = obj.Registry(k);
                try
                    if obj.matches(e.obj, E)
                        claimantID = e.id;
                        break
                    end
                catch err
                    warning('FigureEventHub:MatchError', ...
                        'Error in matches() for %s: %s', class(e.obj), err.message);
                end
            end

            % if the claimant changed
            if ~isequaln(obj.HoverID, claimantID)

                % leave previous claimant
                if ~isnan(obj.HoverID)
                    previousIdx = obj.indexOfID(obj.HoverID);
                    if ~isempty(previousIdx)
                        leaveEvent = obj.syntheticEventLike(E, "Leave", obj.Registry(previousIdx).obj);
                        obj.safeCall(obj.Registry(previousIdx).obj, 'onLeave', leaveEvent);
                        obj.notifyListeners(leaveEvent);
                    end
                end

                % enter new claimant
                if ~isnan(claimantID)
                    newIdx = obj.indexOfID(claimantID);
                    if ~isempty(newIdx)
                        enterEvent = obj.syntheticEventLike(E, "Enter", obj.Registry(newIdx).obj);
                        obj.safeCall(obj.Registry(newIdx).obj, 'onEnter', enterEvent);
                        obj.notifyListeners(enterEvent);
                    end
                end

                % transfer hover to new claimant
                obj.HoverID = claimantID;
            end
        end

        function tf = matches(~, h, E)
        %MATCHES Safely ask a registrant whether it claims an event.
            tf = false;
            if isvalid(h)
                tf = h.matches(E);
            end
        end

        function updateKeyboardState(obj, kind, evt)
        %UPDATEKEYBOARDSTATE Track normalized key/modifier state.
            if ~any(string(kind) == ["KeyPress", "KeyRelease"])
                return
            end

            if ~isa(evt, 'matlab.ui.eventdata.KeyData')
                return
            end

            key = lower(string(evt.Key));
            character = lower(string(evt.Character));
            modifiers = matlabx.ui.interaction.FigureEventHub.canonicalModifiers_(evt.Modifier);

            switch string(kind)
                case "KeyPress"
                    % MATLAB reports currently held modifiers separately
                    % from the pressed key. Include modifier keys themselves
                    % so later mouse events can carry the current chord.
                    obj.ModifierState = matlabx.ui.interaction.FigureEventHub.canonicalModifiers_([modifiers, key]);
                    if obj.isAltKey_(key)
                        obj.disableFigureMenusForAlt_();
                    end

                    if obj.isShortcutLikeKeyEvent_(key, modifiers)
                        obj.ShortcutModifierStateTimestamp = datetime("now");
                    elseif obj.isModifierKey_(key)
                        obj.ShortcutModifierStateTimestamp = NaT;
                    end
                case "KeyRelease"
                    obj.ModifierState = modifiers;
                    if isempty(obj.ModifierState)
                        obj.ShortcutModifierStateTimestamp = NaT;
                    end

                    if obj.isAltKey_(key)
                        obj.restoreFigureMenusAfterAlt_();
                    end
            end

            obj.LastKey = key;
            obj.LastHotkey = matlabx.keyboard.normalize(key, character, obj.ModifierState);
            obj.LastKeyTimestamp = datetime("now");
        end

        function expireStaleShortcutModifierState(obj, kind)
        %EXPIRESTALESHORTCUTMODIFIERSTATE Clear stale shortcut modifiers.
        %
        %   Some MATLAB UI operations, such as menu accelerators followed by a
        %   modal progress dialog, can prevent the matching key-release event
        %   from reaching the hub. Only shortcut-like modifier states expire;
        %   held modifier keys from ordinary interaction remain live.
            if string(kind) ~= "Down" ...
                    || isempty(obj.ModifierState) ...
                    || isnat(obj.ShortcutModifierStateTimestamp)
                return
            end

            if datetime("now") - obj.ShortcutModifierStateTimestamp > obj.ShortcutModifierStateMaxAge
                obj.ModifierState = string.empty(1,0);
                obj.ShortcutModifierStateTimestamp = NaT;
            end
        end

        function tf = isShortcutLikeKeyEvent_(obj, key, modifiers)
        %ISSHORTCUTLIKEKEYEVENT_ True for menu-accelerator style key chords.
            key = lower(string(key));
            modifiers = matlabx.ui.interaction.FigureEventHub.canonicalModifiers_(modifiers);

            primaryShortcutModifiers = ["meta", "control"];

            tf = ~isempty(modifiers) ...
                && any(ismember(modifiers, primaryShortcutModifiers)) ...
                && ~obj.isModifierKey_(key);
        end

        function tf = isModifierKey_(~, key)
        %ISMODIFIERKEY_ True when key names a modifier rather than content key.
            key = lower(string(key));
            modifierKeys = ["shift", "control", "alt", "meta", "command", "option", "ctrl"];
            tf = any(key == modifierKeys);
        end

        function tf = isAltKey_(~, key)
        %ISALTKEY_ True when a key name maps to the alt/option modifier.
            key = lower(string(key));
            tf = any(key == ["alt", "option"]);
        end

        function disableFigureMenusForAlt_(obj)
        %DISABLEFIGUREMENUSFORALT_ Disable top-level menus while alt is down.
        %
        %   This prevents MATLAB/platform menubar keyboard focus from stealing
        %   subsequent modifier-release events. The original Enable states are
        %   cached so disabled menus remain disabled after restoration.
            try
                if ~isempty(obj.AltDisabledMenus)
                    return
                end

                menus = obj.Fig.Children(arrayfun(@(h) isa(h, "matlab.ui.container.Menu"), obj.Fig.Children));
                if isempty(menus)
                    return
                end

                obj.AltDisabledMenus = menus;
                obj.AltDisabledMenuEnableState = string({menus.Enable});

                wasEnabled = obj.AltDisabledMenuEnableState == "on";

                % Only toggle menus that were enabled. Restoring all previous
                % states later preserves app-specific disabled menu items.
                set(menus(wasEnabled), "Enable", "off");
                drawnow limitrate
            catch
                % Menu focus prevention is best-effort only; event routing
                % should never fail because a figure has unusual menu objects.
                obj.AltDisabledMenus = matlab.ui.container.Menu.empty(1,0);
                obj.AltDisabledMenuEnableState = string.empty(1,0);
            end
        end

        function restoreFigureMenusAfterAlt_(obj)
        %RESTOREFIGUREMENUSAFTERALT_ Restore menu enabled states after alt.
        %
        %   This pairs with disableFigureMenusForAlt_. It is intentionally
        %   best-effort because figures may delete or rebuild menus while a key
        %   is held; stale handles are skipped and bookkeeping is always reset.
            try
                menus = obj.AltDisabledMenus;
                enableState = obj.AltDisabledMenuEnableState;

                if isempty(menus)
                    return
                end

                keep = isvalid(menus);
                menus = menus(keep);
                enableState = enableState(keep);

                for i = 1:numel(menus)
                    menus(i).Enable = char(enableState(i));
                end
            catch
                % Restoration is best-effort; reset bookkeeping either way so
                % a later alt press can try again with the current menu state.
            end

            obj.AltDisabledMenus = matlab.ui.container.Menu.empty(1,0);
            obj.AltDisabledMenuEnableState = string.empty(1,0);
        end

        function call(~, h, E)
        %CALL Dispatch an event to the matching registrant callback method.
            if ~isvalid(h), return; end

            switch E.Kind
                case 'Down',   h.onDown(E);
                case 'Move',   h.onMove(E);
                case 'Up',     h.onUp(E);
                case 'Scroll', h.onScroll(E);
                case 'KeyPress',   h.onKeyPress(E);
                case 'KeyRelease', h.onKeyRelease(E);
                case 'Enter',      h.onEnter(E);
                case 'Leave',      h.onLeave(E);
            end
        end

        function safeCall(~, h, methodName, E)
        %SAFECALL Call an optional transition method without breaking routing.
            if isvalid(h)
                try
                    h.(methodName)(E);
                catch err
                    warning('FigureEventHub:SafeCallError', ...
                        'Error in %s.%s: %s', class(h), methodName, err.message);
                end
            end
        end

        function notifyListeners(obj, E)
        %NOTIFYLISTENERS Notify passive listeners for the event kind.
            L = obj.ListenerRegistry.(E.Kind);
            for i = 1:numel(L)
                try
                    L(i).Fcn(E);
                catch err
                    warning('FigureEventHub:ListenerError', ...
                        'Error in %s listener ID %d: %s', E.Kind, L(i).id, err.message);
                end
            end
        end

        function idx = indexOfID(obj, id)
        %INDEXOFID Find a registrant index from its stable hub ID.
            ids = [obj.Registry.id];
            idx = find(ids == id, 1, 'first');
        end

        function pruneInvalidRegistrants(obj)
        %PRUNEINVALIDREGISTRANTS Remove deleted registrant handles.
            keep = false(1, numel(obj.Registry));
            for i = 1:numel(obj.Registry)
                keep(i) = isvalid(obj.Registry(i).obj);
            end

            removedIDs = [obj.Registry(~keep).id];
            obj.Registry = obj.Registry(keep);

            if ~isempty(removedIDs)
                if any(removedIDs == obj.HoverID)
                    obj.HoverID = NaN;
                end
                if any(removedIDs == obj.CaptureID)
                    obj.CaptureID = NaN;
                end
            end
        end

        function pruneInvalidListeners(obj, kind)
        %PRUNEINVALIDLISTENERS Placeholder for listener cleanup policy.
            L = obj.ListenerRegistry.(kind);
            keep = true(1, numel(L));

            for i = 1:numel(L)
                % function handles generally remain valid unless the target scope is gone;
                % we just leave them and let notifyListeners catch errors.
                keep(i) = true;
            end

            obj.ListenerRegistry.(kind) = L(keep);
        end

        function sortRegistry(obj)
        %SORTREGISTRY Keep registrants sorted by descending priority.
            if isempty(obj.Registry)
                return
            end
            [~, ord] = sort([obj.Registry.Priority], 'descend');
            obj.Registry = obj.Registry(ord);
        end

        function sortListeners(obj, kind)
        %SORTLISTENERS Keep passive listeners sorted by descending priority.
            L = obj.ListenerRegistry.(kind);
            if isempty(L)
                return
            end
            [~, ord] = sort([L.Priority], 'descend');
            obj.ListenerRegistry.(kind) = L(ord);
        end

        function E2 = syntheticEventLike(obj, E, kind, claimant)
        %SYNTHETICEVENTLIKE Create an Enter/Leave event from an existing event.
        %
        %   Synthetic hover events reuse the current target, raw event, and
        %   keyboard state, but identify the registrant that entered or left
        %   hover through HubEvent.Claimant.
            E2 = matlabx.ui.interaction.HubEvent(obj.Fig, E.Target, kind, E.RawEvent, ...
                "ModifierState", E.ModifierState, ...
                "LastKey", E.LastKey, ...
                "LastHotkey", E.LastHotkey, ...
                "LastKeyTimestamp", E.LastKeyTimestamp, ...
                "Claimant", claimant);
        end

    end

    methods (Static)

        function requiredMethods = getRequiredMethods()
        %GETREQUIREDMETHODS Return the registrant callback protocol.
            requiredMethods = { ...
                'matches', ...
                'onDown', ...
                'onUp', ...
                'onMove', ...
                'onScroll', ...
                'onKeyPress', ...
                'onKeyRelease', ...
                'onEnter', ...
                'onLeave'};
        end

        function kinds = supportedKinds()
        %SUPPORTEDKINDS Return figure-backed and synthetic event kind names.
            kinds = {'Down', 'Move', 'Up', 'Scroll', ...
                'KeyPress', 'KeyRelease', 'Enter', 'Leave'};
        end

        function modifiers = canonicalModifiers_(modifiers)
        %CANONICALMODIFIERS_ Normalize modifier names and ordering.
            modifiers = lower(string(modifiers));
            modifiers(modifiers == "") = [];
            modifiers(modifiers == "command") = "meta";
            modifiers(modifiers == "option") = "alt";
            modifiers(modifiers == "ctrl") = "control";

            order = ["shift", "control", "alt", "meta"];
            modifiers = intersect(order, unique(modifiers, "stable"), "stable");
        end

    end

end
