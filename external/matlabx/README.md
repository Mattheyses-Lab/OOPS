# matlabx

[![License: GPL-2.0-or-later](https://img.shields.io/badge/License-GPL--2.0--or--later-blue.svg)](LICENSE)

matlabx is a MATLAB framework for building richer apps, image viewers, and
interactive analysis tools. Its current center of gravity is custom app and
component development: normalized figure-level event routing, reusable UI
components, `Image5D` image-data normalization, and `ImageAxes`, an extensible
image-display component with pluggable tools and overlays.

The project is under active development. APIs may still move as the package
gets sharper.

> Note: matlabx is an independent project and is not affiliated with or
> endorsed by MathWorks.

## License

matlabx is free software licensed under the GNU General Public License, version
2 or later (`GPL-2.0-or-later`). See [LICENSE](LICENSE) for the full license
text. Third-party notices for bundled dependencies, lookup tables, colormaps,
and external utilities are listed in [NOTICE](NOTICE).

## Highlights

- **Custom app interaction infrastructure**: `FigureEventHub`, `HubEvent`, and
  keyboard helpers normalize MATLAB figure callbacks into a shared routing
  system for mouse, key, scroll, hover, drag, modifier, and hotkey behavior.
- **ImageAxes**: an `Image5D`-backed image display component with C/Z/T
  navigation, scalar/composite rendering, per-component display state,
  context menus, status/help windows, linked axes, and a pluggable tool system.
- **Image5D**: a normalization layer for in-memory and Bio-Formats-backed
  multi-component, Z-stack, and time-series image data.
- **Overlay and tool primitives**: first-party tools for zooming, display
  limits, colormaps, colorbars, boxes, points, lines, rectangles, and rectangle
  selection.
- **Reusable UI components**: custom containers and controls such as accordion
  panels and scalar/range sliders.
- **Small apps built from the pieces**: `quickshow`, `Viewer5D`,
  `ParamsDialog`, `ColormapSelector`, `TextWindow`, and early analysis/tuning
  apps.
- **Supporting utilities**: logging, settings, machine-state persistence, UI
  calibration, colormap registry, file/path helpers, string/struct helpers,
  keyboard normalization, plotting helpers, and image processing helpers.

Point detection, point clustering, and image-analysis utilities are present and
useful, but they are still evolving around current analysis needs. They are not
yet the primary stable API surface of the project.

## Package Map

- `matlabx.ui.interaction`: event hubs, normalized event payloads, command
  routing, and keyboard/mouse interaction plumbing
- `matlabx.ui.axes`: axes-backed visual components, `ImageAxes`, overlays,
  tools, context menus, display collaborators, and events
- `matlabx.image`: image data models, Bio-Formats-backed IO, processing, masks,
  ROIs, and measurement helpers
- `matlabx.ui.container`: custom container-style components
- `matlabx.ui.control`: custom value/input controls
- `matlabx.app`: complete apps and reusable dialogs
- `matlabx.colors`: colormap registry, color names, and color helpers
- `matlabx.config`: user settings and machine-local state
- `matlabx.logging`: structured logging runtime
- `matlabx.analysis.cluster`: evolving point-clustering models and metrics
- `matlabx.files`, `matlabx.keyboard`, `matlabx.struct`, `matlabx.string`,
  `matlabx.utils`: supporting utilities

## Installation And Setup

Clone or place this repository somewhere stable, then add the repository root
to the MATLAB path:

```matlab
addpath('/path/to/matlabx')
```

For a new install, run:

```matlab
matlabx.setup.run()
```

That setup routine:

- adds the matlabx root and bundled external libraries to the MATLAB path
- configures the bundled Bio-Formats dependency
- runs UI calibration
- saves the MATLAB path

For a lighter manual setup, run pieces individually:

```matlab
matlabx.setup.searchPath()
matlabx.setup.bioFormats()
matlabx.setup.uiCalibration()
```

The setup, settings, and machine-state files use MATLAB's `prefdir` under a
`matlabx` folder.

## Quick Usage

Show an image quickly:

```matlab
I = imread("rice.png");
[ax, fig] = matlabx.app.quickshow(I);
```

Open the 5D image viewer:

```matlab
I = matlabx.image.Image5D.fromComponents({imread("rice.png")});
viewer = matlabx.app.Viewer5D(I);
```

Use `ImageAxes` directly in a UI:

```matlab
fig = uifigure;
I = matlabx.image.Image5D.demo();

ax = matlabx.ui.axes.ImageAxes(fig, ...
    "ImageData", I, ...
    "Tools", ["Zoom", "Colorbar", "ChooseColormap", "DisplayLimits"], ...
    "Units", "normalized", ...
    "Position", [0 0 1 1]);
```

Create a demo multi-component image:

```matlab
I = matlabx.image.Image5D.demo(256, 256, 3, 10, 10, 'uint16');
[ax, fig] = matlabx.app.quickshow(I, "ComponentColorMode", "colors");
```

Open a parameter dialog:

```matlab
params = struct("Sigma", 1.5, "Threshold", 0.05, "UseMask", true);
out = matlabx.app.ParamsDialog(params);
```

## Custom Event Routing

Many matlabx components assume figure input is routed through
`matlabx.ui.interaction.FigureEventHub`. The hub installs one coordinated set
of figure callbacks, converts raw MATLAB callback data into normalized
`HubEvent` objects, and dispatches those events to registered components and
tools.

This matters because MATLAB apps often need several interactive behaviors at
once: ordinary clicks, context clicks, modifier-clicks, scroll zoom, drag
capture, hover state, keyboard shortcuts, and tool-specific hotkeys. Without a
shared router, those callbacks tend to fight each other.

The hub handles:

- mouse down, move, up, scroll, key press, and key release events
- synthetic enter and leave events when hover ownership changes
- priority-based claiming when multiple components match the same event
- optional drag capture so a component keeps receiving move/up events during a
  drag
- preserved pre-existing callbacks as low-priority listeners
- modifier-state tracking for mouse gestures
- shortcut-style modifier cleanup to avoid stale keys after menu accelerators,
  dialogs, or interrupted UI interaction
- a targeted alt/option menubar-focus workaround so alt can remain usable as an
  interaction modifier

`HubEvent` centralizes event normalization. Useful fields include:

- `Kind`: `"Down"`, `"Move"`, `"Up"`, `"Scroll"`, `"KeyPress"`,
  `"KeyRelease"`, `"Enter"`, or `"Leave"`
- `Target`, `CurrentAxes`, `CurrentObject`, and `CurrentPointFigure`
- `SelectionType`: raw MATLAB click type
- `MouseAction`: normalized actions such as `"click"`, `"contextclick"`,
  `"extendclick"`, `"doubleclick"`, `"move"`, `"up"`, or `"scroll"`
- `MouseChord`: modifiers plus action, such as `"meta+click"` or
  `"shift+extendclick"`
- `Key`, `Character`, `Modifier`, `ModifierState`, and normalized `Hotkey`
- `LastKey`, `LastHotkey`, and `LastKeyTimestamp`
- `VerticalScrollCount`
- `Handled` and `StopPropagation`

Modifier names are normalized to `shift`, `control`, `alt`, and `meta`.
`CurrentPointFigure` is stored in figure pixel coordinates, which is useful for
screen-pixel drag thresholds that feel consistent across image sizes and zoom
levels.

Registering a component directly:

```matlab
hub = matlabx.ui.interaction.FigureEventHub.ensure(fig);
id = hub.register(myComponent, ...
    "Priority", 10, ...
    "CaptureDuringDrag", true);
```

The registered object implements `matches(E)` and any event hooks it wants:

```matlab
function tf = matches(obj, E)
    tf = isequal(ancestor(E.Target, "axes"), obj.Axes);
end

function onDown(obj, E)
    if E.MouseChord == "control+contextclick"
        obj.deleteThingUnderCursor(E)
        E.stop()
    end
end
```

Print event payloads while debugging:

```matlab
E.print()
S = E.toStruct();
```

The event hub demo is useful when testing gestures and platform-specific
callback behavior:

```matlab
matlabx.ui.interaction.demos.HubEventDemo()
```

## Image5D

`matlabx.image.Image5D` is the image-data normalization layer used by
`ImageAxes`, `Viewer5D`, and `quickshow`. It gives apps a common way to work
with images that may come from ordinary MATLAB arrays, component arrays, or
file-backed sources.

Create an in-memory image from one or more components:

```matlab
I1 = imread("channel1.tif");
I2 = imread("channel2.tif");

I = matlabx.image.Image5D.fromComponents({I1, I2}, ...
    "Names", ["DAPI", "Actin"]);
```

Load a file through Bio-Formats:

```matlab
I = matlabx.image.Image5D.fromFile("experiment.czi", ...
    "SeriesIndex", 1, ...
    "LoadOnCreate", true);
```

Use a file picker for Bio-Formats-supported images:

```matlab
I = matlabx.image.Image5D.fromFileDialog("LoadOnCreate", true);
```

Useful image metadata and shape properties include:

```matlab
I.Size
I.NumComponents
I.SizeZ
I.SizeT
I.Components
I.AllMetadata
```

`Image5D` uses components as the primary abstraction. When the components are
compatible scalar channels, `ImageAxes` can display individual components or a
merged color composite.

## ImageAxes

`matlabx.ui.axes.ImageAxes` is the main reusable image-display component. It is
a `matlab.ui.componentcontainer.ComponentContainer` that displays the selected
`C/Z/T` plane or composite from an `Image5D` object, manages display state,
hosts overlays and tools, and routes normalized figure events to those tools.

Basic construction:

```matlab
fig = uifigure;
I = matlabx.image.Image5D.demo();

ax = matlabx.ui.axes.ImageAxes(fig, ...
    "ImageData", I, ...
    "Tools", ["Zoom", "Colorbar", "ChooseColormap"], ...
    "Units", "normalized", ...
    "Position", [0 0 1 1]);
```

Navigate through dimensions:

```matlab
ax.C = 2;
ax.Z = 5;
ax.T = 3;
ax.ShowComposite = "on";
```

Set current-component display properties:

```matlab
ax.C = 1;
ax.CLim = [100 2000];
ax.Colormap = gray(256);
```

For targeted per-component edits, prefer the helper methods:

```matlab
ax.setComponentCLim([100 2000]);          % current component
ax.setComponentCLim([100 2000], [1 3]);   % components 1 and 3
ax.setComponentColor("cyan", 1);
ax.setComponentColormap(hot(256), 2);
```

The full-state properties are useful for restoring saved display state or
synchronizing axes. They update stored values without automatically changing
`ComponentColorMode`:

```matlab
ax.ComponentCLims = {[0 500], [0 800], [0 1200]};
ax.ComponentColors = {'cyan', 'magenta', 'yellow'};
ax.ComponentColormaps{2} = hot(256);
ax.ComponentColorMode = 'colors';  % or 'luts'
```

Viewport/navigation API:

```matlab
S = ax.getViewport();
ax.setViewportCenter([128 256]);
ax.setViewportSize([128 256]);
ax.setZoomFactor(0.5);
ax.resetViewport();
```

`ImageAxes` maintains the image aspect ratio when setting viewport size or
limits. The visible viewport and zoom factor are two views of the same
underlying navigation state: changing one updates the other. Programmatic
viewport changes are center-anchored; interactive zoom gestures are
cursor-anchored when possible.

Useful status and diagnostics:

```matlab
ax.openStatusWindow()
status = ax.getStatusSummary();
ax.debug("IncludeSizeDiagnostics", true)
```

### Tools

Tools are installed by assigning names to `ax.Tools`. Reading `ax.Tools`
returns the installed tool objects:

```matlab
ax.Tools = ["Zoom", "Colorbar", "ChooseColormap", "DisplayLimits", ...
    "Box", "Point", "Line", "Rectangle", "RectangleSelect"];
ax.Tools.Box.BoxSize = 40;
```

Available tool names can be queried:

```matlab
matlabx.ui.axes.ImageAxes.getToolNames()
matlabx.ui.axes.ImageAxes.getDefaultTools()
```

Current first-party tools include:

- `Zoom`: zooming, cursor-follow navigation, zoom-level menu, and viewport-box
  display while active
- `Colorbar`: colorbar display support
- `ChooseColormap`: colormap selection
- `DisplayLimits`: opens the host-owned display-limits slider dialog
- `Box`: square box region creation, activation, selection, movement, and
  deletion
- `Point`: point overlay creation, activation, selection, movement, and
  deletion
- `Line`: line drawing, endpoint editing, midpoint translation,
  symmetric/fixed-angle extension, selection, and deletion
- `Rectangle`: axis-aligned rectangle drawing, body translation, handle
  resizing, square/center-constrained resizing, selection, and deletion
- `RectangleSelect`: drag-box selection of existing overlays, with shift
  toggling selection membership
- `DrawRectangle`: specialized push-style rotated rectangle drawing and
  measurement annotations

The interactive overlay tools share a deliberately consistent gesture grammar:

- click an existing overlay to activate it
- `alt+click` an overlay body to deactivate
- `shift+extendclick` an overlay to toggle selection membership
- `control+contextclick` an overlay to delete it
- drag a body, midpoint, point, or handle to move/edit geometry
- `shift+doubleclick` empty image space to clear selection for that tool

Line and rectangle creation use a small screen-pixel drag threshold, so an
accidental click does not leave an invisible zero-length line or zero-size
rectangle. Interactive overlay geometry is clamped to image bounds.

Tool subclasses inherit from `matlabx.ui.axes.AxesTool`. A custom tool usually:

- calls the `AxesTool` constructor with a name, style, icon, hotkey, and
  routing flags
- overrides lifecycle hooks such as `onInstall`, `onEnabled`, `onDisabled`, or
  `onPush`
- implements event hooks such as `onDown`, `onMove`, `onScroll`, or passive
  variants
- optionally contributes context-menu items with `contributeContextMenu`
- optionally contributes help text with `getHelpSummary`, `getUsageHelp`,
  `getBindingHelp`, and `getNotesHelp`

Minimal custom tool sketch:

```matlab
classdef MyTool < matlabx.ui.axes.AxesTool
    methods
        function obj = MyTool(host)
            obj@matlabx.ui.axes.AxesTool(host, "MyTool", ...
                "Style", "state", ...
                "AxesType", "image", ...
                "ToggleHotkey", matlabx.keyboard.hotkey("m"), ...
                "InterceptsDown", true);
        end

        function onDown(obj, E)
            if E.MouseChord == "click"
                xy = obj.Host.mainAxes.CurrentPoint(1, 1:2);
                disp(xy)
                E.stop()
            end
        end
    end
end
```

Tool hotkeys should be declared with `matlabx.keyboard.hotkey` so tool authors
do not need to memorize normalized hotkey string syntax:

```matlab
matlabx.keyboard.hotkey("z", "Modifiers", ["shift", "meta"])
```

### Context Menus

`ImageAxes` owns a context-menu manager that builds a small set of built-in
menus and lets tools contribute their own commands. The default menu includes:

- `Image > Component Color`
- `Image > Color Mode`
- `Image > Colormap...`
- `Image > Properties...`
- `Image > Metadata...`
- `Display > Viewport Box`
- `Reset View`
- `Status...`
- tool menus such as `Zoom > Level`, `Box > Select All`, and
  `Rectangle > Delete Selected`

Choose which built-ins are available with `ContextMenuItems`:

```matlab
ax.ContextMenuItems = ["Image", "Display", "ResetView", "Status"];
matlabx.ui.axes.ImageAxes.getContextMenuItemNames()
```

You can also expose individual built-ins without their parent group:

```matlab
ax.ContextMenuItems = ["ResetView", "ComponentColor", "ViewportBox"];
```

The order of `ContextMenuItems` is honored for top-level built-ins. Tool menus
are contributed below the built-ins and separated from them automatically.

### Overlays

`ImageAxes` owns an overlay manager available as `ax.Overlays`. Overlays are
graphics objects tied to image coordinates and C/Z/T applicability. The manager
owns overlay lifetime and shared state such as active, hovered, and selected
IDs; tools and apps decide what user interactions mean.

Add many detected points as a display overlay:

```matlab
points = matlabx.image.measure.detectPoints(I, "Method", "log");

ov = ax.Overlays.add("PointSet", ...
    "Points", points, ...
    "Marker", "o", ...
    "MarkerEdgeColor", [0 0 0], ...
    "MarkerFaceColor", [1 1 1]);
```

Add interactive-style single-object overlays:

```matlab
pt = ax.Overlays.add("Point", ...
    "Position", [96 128]);

box = ax.Overlays.add("Box", ...
    "Center", [128 128], ...
    "BoxSize", 40, ...
    "Label", "ROI 1");

ln = ax.Overlays.add("Line", ...
    "Endpoints", [50 50; 200 120], ...
    "LineColor", [1 1 0]);

rect = ax.Overlays.add("Rectangle", ...
    "Position", [40 60 120 80]);
```

Overlay IDs are string identifiers. If the caller does not provide one,
overlays generate their own ID:

```matlab
ids = ax.Overlays.ids();
ax.Overlays.setActive(ids(1));
ax.Overlays.setSelected(ids(1:3));
ax.Overlays.remove(ids(1));
```

First-party overlays currently include:

- `matlabx.ui.axes.overlays.Box`
- `matlabx.ui.axes.overlays.Point`
- `matlabx.ui.axes.overlays.Line`
- `matlabx.ui.axes.overlays.Rectangle`
- `matlabx.ui.axes.overlays.PointSet`
- `matlabx.ui.axes.overlays.PointClusters`

The overlay base class is intentionally small. Custom overlays inherit from
`matlabx.ui.axes.ImageAxesOverlay`, own their graphics handles, implement
`updateGeometry` and `updateAppearance`, and call `registerGraphics` for
hit-test ownership and manager lookup.

## Reusable Components And Apps

matlabx includes smaller UI pieces that are useful outside `ImageAxes`.

`matlabx.ui.control.Slider` supports both range and scalar slider behavior. It
can show or hide edit fields at construction time:

```matlab
fig = uifigure;
g = uigridlayout(fig, [1 1]);

s = matlabx.ui.control.Slider(g, ...
    "Title", "Intensity", ...
    "Limits", [0 255], ...
    "Value", [20 180], ...
    "ShowFill", "on");
```

Create a simple one-thumb slider without edit fields:

```matlab
s = matlabx.ui.control.Slider(g, ...
    "ValueMode", "scalar", ...
    "ShowEditFields", "off", ...
    "ShowFill", "on", ...
    "Limits", [0 100], ...
    "Value", 40);
```

Useful general apps and dialogs include:

- `matlabx.app.quickshow`: quick image inspection with an `ImageAxes`
- `matlabx.app.Viewer5D`: viewer app for `Image5D` images
- `matlabx.app.ParamsDialog`: quick parameter editing from structs/settings
- `matlabx.app.ColormapSelector`: colormap picker backed by the registry
- `matlabx.app.TextWindow`: reusable formatted text/status window
- `matlabx.app.SliderGroupDialog`: grouped slider dialog used by display
  limits controls

## Colormaps And Colors

`matlabx.colors.maps.Registry` discovers bundled colormaps and exposes a common
lookup API. File-backed maps live under `assets/colormaps/<Category>/*.mat`.
The `MATLAB` category is generated at runtime from the user's installed MATLAB
built-in colormap functions; matlabx does not redistribute MathWorks colormap
data.

List categories and maps:

```matlab
cats = matlabx.colors.maps.Registry.categories();
names = matlabx.colors.maps.Registry.names("Brewer");
allNames = matlabx.colors.maps.Registry.names();
```

Load a map:

```matlab
M = matlabx.colors.maps.Registry.map("Viridis", "Matplotlib");
M = matlabx.colors.maps.Registry.map("parula", "MATLAB");
```

Use the registry with `ImageAxes`:

```matlab
ax.setComponentColormap( ...
    matlabx.colors.maps.Registry.map("Inferno", "Matplotlib"));
```

If a colormap name is unique across categories, one-argument lookup is allowed.
If not, specify the category:

```matlab
obj = matlabx.colors.maps.Registry.get("Fire", "Fiji");
```

Third-party colormap attributions are documented in [NOTICE](NOTICE). The
`Colors` and `Custom` categories are matlabx-authored maps.

## Logging

For simple app and library messages, use the static facade:

```matlab
matlabx.Log.INFO("Opening viewer")
matlabx.Log.WARN("Using fallback colormap")
matlabx.Log.EXCEPTION(ME)
```

The facade owns a session logger and applies a `matlabx.config.Logging` policy.
The logger stores structured entries in memory and can write to command-window,
UI, and file sinks.

Configure policy:

```matlab
matlabx.Log.configure("Level", "INFO", "Detail", "normal")
matlabx.Log.configure("CommandWindowLevel", "INFO", ...
    "FileLevel", "DEBUG", ...
    "FileDetail", "debug")
matlabx.Log.configure("SourceDetail", "full")
```

`Level` is the minimum emitted level: `DEBUG`, `INFO`, `WARN`, or `ERROR`.
`Detail` controls formatted output only; structured entries retain full data.
`SourceDetail` controls compact versus full auto-detected source names.
`ShowDebugOutput` remains for older settings, but new code should use
`Level="DEBUG"`.

Get the underlying logger when needed:

```matlab
log = matlabx.Log.get();
log.setFileSink(fullfile(tempdir, "matlabx.log"), true);
log.setUISink(@(lines) disp(strjoin(lines, newline)), true);
```

Export stored entries:

```matlab
T = matlabx.Log.asTable();
lines = matlabx.Log.exportText();
```

An app can create its own facade over `matlabx.logging.Logger` while still
using the same policy object. The usual pattern is:

1. Keep app preferences/settings in the app.
2. Build or load a `matlabx.config.Logging` object from those preferences.
3. Call `logger.configure(config)`.
4. Expose app-specific convenience methods such as `MyApp.Log.INFO(...)`.

That keeps the app-level facade thin while leaving filtering, formatting,
structured entries, and sink behavior in `matlabx.logging.Logger`.

## Settings, Machine State, And UI Calibration

User settings are managed by `matlabx.config.Settings` and saved as JSON:

```matlab
settings = matlabx.config.Settings.get();
settings.UI.DefaultFontSize = 14;
settings.Images.DefaultColormap = 'gray';
matlabx.config.Settings.saveActive();
```

For everyday use, the `matlabx.Settings` facade provides one-line get/set
helpers:

```matlab
settings = matlabx.Settings.get();

level = matlabx.Settings.Logging("Level");
matlabx.Settings.Logging("Level", "DEBUG");
matlabx.Settings.Logging("Detail", "verbose");

fontSize = matlabx.Settings.UI("DefaultFontSize");
matlabx.Settings.Images("DefaultColormap", 'gray');

matlabx.Settings.save();
```

Print current settings:

```matlab
matlabx.Settings.print()
matlabx.Settings.print("Logging")
```

Machine-local state is for computer-specific values such as calibration:

```matlab
matlabx.config.MachineState.set('LastDataFolder', pwd)
folder = matlabx.config.MachineState.get('LastDataFolder', pwd);
matlabx.config.MachineState.print()
```

Some MATLAB UI measurements vary by platform, display scaling, and release.
matlabx stores machine-local calibration data so app sizing and placement can
be more predictable.

Run calibration manually with:

```matlab
matlabx.setup.uiCalibration()
```

For common values and measurements, use the `matlabx.UICal` facade:

```matlab
ppi = matlabx.UICal.pixelsPerInch();
px = matlabx.UICal.pt2px(12);
h = matlabx.UICal.panelChromeHeight(14, "FontUnits", "pixels");

matlabx.UICal.print()
```

Cached calibration is checked against the current MATLAB version, display
scale, and monitor geometry. If the display setup changes, matlabx will
recalibrate automatically when needed. You can force it with:

```matlab
matlabx.UICal.recalibrate()
```

## Image Analysis Utilities

matlabx includes early but useful image-analysis helpers. This area will grow
as analysis needs evolve.

Point detection:

```matlab
[points, info] = matlabx.image.measure.detectPoints(I, ...
    "Method", "log", ...
    "Sigma", 1.5, ...
    "MinDistance", 3);
```

Supported methods include:

- `"regionalMaxima"`: reconstruction/open-close puncta detector implemented by
  `detectPuncta`
- `"extendedMaxima"`: `imextendedmax`-based detector with an `H` prominence
  threshold
- `"surf"`: SURF feature detector wrapper around `detectSURFFeatures`
- `"log"`: Laplacian-of-Gaussian blob response plus local maxima
- `"dog"`: Difference-of-Gaussians blob response plus local maxima

Method-specific helpers are available when a direct call is clearer:

```matlab
points = matlabx.image.measure.detectPuncta(I, "DiskRadius", 2);
points = matlabx.image.measure.detectLogPuncta(I, "Sigma", 1.5);
points = matlabx.image.measure.detectDogPuncta(I, "Sigma1", 1, "Sigma2", 2);
points = matlabx.image.measure.detectExtendedMaximaPuncta(I, "H", 0.05);
points = matlabx.image.measure.detectSurfPoints(I, "MetricThreshold", 50);
```

Lower-level processing helpers include:

```matlab
Rlog = matlabx.image.process.laplacianOfGaussian(I, "Sigma", 1.5);
Rdog = matlabx.image.process.differenceOfGaussians(I, "Sigma1", 1, "Sigma2", 2);
[points, mask, values] = matlabx.image.measure.findLocalMaxima(Rlog);
```

Point clustering is available through `matlabx.analysis.cluster.PointClusters`,
but should be treated as an evolving analysis model rather than a settled core
API:

```matlab
C = matlabx.analysis.cluster.PointClusters(points, ...
    "ClusterMethod", "dbscan", ...
    "MinPointsPerCluster", 5);

metrics = C.exportClusterMetrics();
```

The early tuning app wires point detection, clustering, overlays, and metrics
together:

```matlab
app = matlabx.app.PointClusterTuner(I);
```

## Tips

- Prefer package-qualified names in library code, for example
  `matlabx.ui.axes.ImageAxes`.
- Prefer `ImageData` over `CData` in new `ImageAxes` code. `CData` remains a
  convenience input for raw MATLAB image arrays.
- Use `matlabx.app.quickshow` for fast inspection and
  `matlabx.app.Viewer5D` when working with `Image5D`.
- Use `matlabx.keyboard.hotkey` for tool hotkey declarations and compare
  against normalized `HubEvent.Hotkey` or `HubEvent.MouseChord`.
- Use `FigureEventHub` and `CommandRouter` when an app needs coordinated
  figure-level mouse/key behavior.
- Use `matlabx.config.Settings` for user preferences and
  `matlabx.config.MachineState` for machine-specific cached state.
- Use `matlabx.struct.prettyPrint(S, "StringArrayStyle", "lines")` for
  readable status/help structs that contain string arrays.

## Roadmap

Near-term directions include:

- Continued maturation of `ImageAxes`, overlays, and first-party tools
- A clearer public pattern and examples for custom overlay subclasses
- Tool-contributed context menus and help docs with less hardcoding over time
- More custom UI containers, controls, and layout managers
- A customizable data-plotting axes component with the same pluggable tool
  model as `ImageAxes`
- More example apps built from the reusable UI pieces
- More image-analysis functions for processing, measurement, masks, ROIs, and
  workflows around `Image5D`
- Continued point-detection and clustering work as downstream analysis needs
  become clearer
- Serialization/restoration of `ImageAxes` view and display state
- More polish around setup, documentation, demos, and compatibility checks
