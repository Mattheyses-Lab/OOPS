# Object-Oriented Polarization Software (OOPS)

[![version: v1.9.0](https://img.shields.io/badge/version-v1.9.0-green)](https://github.com/Mattheyses-Lab/OOPS/releases)
[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue)](https://opensource.org/license/gpl-3-0/)

A GUI-based MATLAB software package for object-oriented analysis of fluorescence polarization microscopy (FPM) data.

If you use this software, please cite:

*Dean, W. F., Nawara, T. J., Albert, R. M. and Mattheyses, A. L. (2024) PLOS Computational Biology, 20(8). doi: 10.1371/journal.pcbi.1011723.*

The ultimate goal of the software is to retrieve pixel-by-pixel order and orientation statistics. We refer to these throughout as:
- Order - in-plane orientational order of all the dipoles in a single pixel
- Azimuth - ensemble average direction of the dipoles in each pixel, as projected into the sample plane

To run OOPS, you will need:
- (**required**) 4-image FPM stack(s), where individual images were captured using excitation polarizations (or emission analyzer orientations) of 
0°, 45°, 90°, and 135° (counter-clockwise with respect to the horizontal direction in the image)
- (optional) 4-image flat-field stack(s) captured using the same excitation polarizations

For more information, please see our paper describing the software:
[OOPS: Object-Oriented Polarization Software for analysis of fluorescence polarization microscopy images](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1011723)

For more detailed information about our imaging setup and calculations, also see:
[Defining domain-specific orientational order in the desmosomal cadherins](https://www.sciencedirect.com/science/article/pii/S0006349522008293)

## Key features

- Analyze and manage FPM datasets containing multiple experimental conditions and replicates
- Flexible image segmentation: use built-in segmentation schemes, design custom segmentation schemes, or upload masks generated elsewhere
- Calculate a large number of object properties including order and orientation statistics derived from the polarization response data, morphological features measured from the binary image masks, and intensity statistics determined from the raw input data
- Automatically detect object midlines to calculate azimuth orientations relative to biological features of interest
- Group, sort, and filter objects: label objects manually, group objects automatically with k-means clustering, or sort objects based on property values
- Export sortable object data tables for use in other plotting/statistics software
- Export publication-quality images and plots directly from the software with various customization options

## Installation and usage

This software has only been fully tested in MATLAB version `R2024a`. It is not guaranteed to work with any previous versions.

OOPS makes use of several libraries sourced from the [MATLAB File Exchange](https://www.mathworks.com/matlabcentral/fileexchange/) or elsewhere, each of which are subject to their own licenses. These libraries are included with the source in the `lib` directory, so you do not have to download them yourself. However, if you intend to use this software, read the documentation for each library to ensure that your desired use is permitted. The versions included with OOPS may or may not be the latest versions. If you update these libraries yourself, the software is not guaranteed to work. Links to each library and their licenses can be found in the [Sources](#sources) section.

OOPS also relies on several MATLAB toolboxes which you will need to manually add to MATLAB. Links to each toolbox can also be found in the [Sources](#sources) section.

To install this software, dowload the lasest [release](https://github.com/Mattheyses-Lab/OOPS/releases), unzip it, and make sure all associated files/folders are on the MATLAB `PATH`. For help, see [here](https://www.mathworks.com/help/matlab/matlab_env/add-remove-or-reorder-folders-on-the-search-path.html).

Once you have downloaded the software and required toolboxes, you can start up the GUI by simply typing `OOPS` in the command window.

Notice: This product includes color specifications and designs developed by Cynthia Brewer (http://colorbrewer.org/). For further information about each color scheme, visit the ColorBrewer website.

## Sources

#### External Sources

- [Bio-Formats](https://www.openmicroscopy.org/bio-formats/) (bfmatlab, [various open source licenses](https://www.openmicroscopy.org/licensing/))
- [Convert between RGB and Color Names](https://www.mathworks.com/matlabcentral/fileexchange/48155-convert-between-rgb-and-color-names) (colornames, [BSD-3-Clause](https://opensource.org/license/bsd-3-clause/))
- [Colorspace Transformations](https://www.mathworks.com/matlabcentral/fileexchange/28790-colorspace-transformations) (colorspace, [BSD-2-Clause](https://opensource.org/license/bsd-2-clause/))
- [crameri perceptually uniform colormaps](https://www.mathworks.com/matlabcentral/fileexchange/68546-crameri-perceptually-uniform-scientific-colormaps) (crameri_v1.08, [BSD-2-Clause](https://opensource.org/license/bsd-2-clause/))
- [Generate maximally perceptually-distinct colors](https://www.mathworks.com/matlabcentral/fileexchange/29702-generate-maximally-perceptually-distinct-colors) (distinguishable_colors, [BSD-3-Clause](https://opensource.org/license/bsd-3-clause/))
- [export_fig](https://www.mathworks.com/matlabcentral/fileexchange/23629-export_fig) (export_fig, [BSD-3-Clause](https://opensource.org/license/bsd-3-clause/))
- [interparc](https://www.mathworks.com/matlabcentral/fileexchange/34874-interparc) (interparc, [BSD-2-Clause](https://opensource.org/license/bsd-2-clause/))
- [Cyclic color map](https://www.mathworks.com/matlabcentral/fileexchange/57020-cyclic-color-map) (PhaseBar, [BSD-3-Clause](https://opensource.org/license/bsd-2-clause/))
- [wesMap](https://github.com/tristangstanford/wesMap) (wesMap- 1.0.0, [MIT License](https://opensource.org/license/mit/))
- [ColorBrewer: Attractive and Distinctive Colormaps](https://www.mathworks.com/matlabcentral/fileexchange/45208-colorbrewer-attractive-and-distinctive-colormaps) (ColorBrewer, [Apache](https://www.apache.org/licenses/LICENSE-2.0))
- [cmocean perceptually uniform colormaps](https://www.mathworks.com/matlabcentral/fileexchange/57773-cmocean-perceptually-uniform-colormaps) (cmocean, [MIT License](https://opensource.org/license/mit/))

#### MATLAB Toolboxes

- [Image Processing Toolbox](https://www.mathworks.com/products/image.html)
- [Parallel Computing Toolbox](https://www.mathworks.com/products/parallel-computing.html)
- [Signal Processing Toolbox](https://www.mathworks.com/products/signal.html)
- [Statistics and Machine Learning Toolbox](https://www.mathworks.com/products/statistics.html)
- [Curve Fitting Toolbox](https://www.mathworks.com/products/curvefitting.html)


## OOPS 2.0 development

The rewrite is being developed alongside the existing application in `+oops`.
`OOPS` still launches the existing GUI. The new foundation currently supports
project/group/image/object ownership, Image5D-backed four-angle inputs,
input buffer management, model events, nested settings, scalar object results,
object crops, command-window/file/UI logging, object construction from externally
generated masks, and the first redesigned UI. Correction, puncta/filament segmentation, and four-angle polarization analysis
are accessible through `oops.analysis.Analyzer` and the GUI.

The updated matlabx GUI uses MATLAB R2026b toolbar APIs. Headless foundation
and analysis checks also pass in R2025b. Image Processing Toolbox is required for
`oops.analysis.segment.objectsFromMask`. matlabx and Bio-Formats are bundled;
no additional download is required.

From the repository root:

```matlab
oops.setup.run();
settings = oops.config.Settings.load(); % creates user/settings.json on first use
project = oops.model.Project("Experiment", settings);
group = project.addGroup("Condition A");
input = oops.io.readInput("path/to/four-angle-stack.tif");
image = group.addImage(input, "Replicate 1");
project.setActiveImage(image);
frame0 = image.getFrame(1);
```

Frames are ordered 0°, 45°, 90°, 135° counterclockwise. A source must have exactly
four scalar frames along one component, Z, or time axis; mixed axes and RGB
inputs are rejected. `image.FrameLocations` records the mapping to Image5D's
`[component Z T]` coordinates. Input intensities are preserved. Reference images
and more general acquisition layouts are deferred.

`readInput` opens file metadata without loading the full input buffer. Individual
`getFrame` calls can read lazily. `loadInput` and `unloadInput` control that buffer.
Selecting an active image loads its input and keeps the two most recently active
inputs across all groups, matching DesmoSTORM's active-plus-previous policy.
In-memory Image5D sources cannot release their arrays through `unload`; use
file-backed inputs for memory eviction. Each image must own a distinct source.
Numerical `image.Results` remain ordinary arrays/struct fields for this increment
and are not managed by the input cache.

Objects are defined by their parent image's mask. For an already generated mask:

```matlab
pixelLists = oops.analysis.segment.objectsFromMask(mask); % 4-connected by default
image.setMask(mask, pixelLists);
```

Analysis computes the partition. The model validates that it covers the mask
exactly, stores it, replaces the objects, and emits `ObjectsChanged` and
`DataChanged`. Replacing a mask invalidates the previous object handles.
Image-level results are retained when replacing the mask. New objects start
with unavailable scalar measurements. Removing an image or group detaches it rather than deleting it;
deleting a project deletes its still-owned descendants.

Objects expose the non-reference scalar measurements from the original
`OOPSObject`: morphology, centroid coordinates, signal/background statistics,
order statistics, axial azimuth statistics, and midline statistics. These are
stored results initialized to `NaN`; accessing them does not run analysis.
Angles are in degrees, lengths in pixels, and areas in pixels squared. Analysis
can update a subset through `object.setMeasurements(resultStruct)`. Validation
happens before any scalar is changed. Updating parent image results clears the
image-dependent scalar measurements while retaining morphology and midline-only
geometry. Object changes propagate to project `DataChanged` listeners with an
optional `ObjectID` in the event payload.

After setting a mask, for example:

```matlab
object = image.Objects(1);
object.setMeasurements(struct("Area", numel(object.PixelIdxList))); % example supplied result

% Numeric crops accept any array with matching parent-image Y/X dimensions.
[data, geometry, objectMask, validMask] = object.getCrop(image.getFrame(1));

% This returns a transient, in-memory Image5D suitable for a viewer.
[cropInput, geometry, objectMask, validMask] = object.getInputCrop();

% Work with just geometry/membership without reading input pixels.
[objectMask, geometry, validMask] = object.getMask(Margin=5, Square=true);
localPoints = geometry.toLocal([10 20]); % coordinates use [row column]
parentPoints = geometry.toParent(localPoints);
```

Crop windows default to square bounds with five pixels of context for data crops;
`getMask()` defaults to the tight rectangle. Specify `Margin` and `Square` to
change either behavior. The requested square is preserved at image edges, with
out-of-image pixels filled by zero (or `FillValue`). `validMask` identifies actual
parent pixels; `objectMask` identifies only the selected object's pixels,
excluding neighboring objects. `geometry` is an `oops.geometry.Crop` value
containing inclusive `BoundsRC`, `ImageSize`, and derived `OriginRC`/`Size`. Its
`extract` method preserves data class and trailing axes. No crop arrays are saved
on the object. `settings.ObjectDisplay.CropMargin` and `SquareCrop` remain programmatic developer
options. Individual object display is deferred; the GUI currently displays
image-level sources only.

Settings now have these typed domains, inferred from the old settings groups:

| Domain | Responsibility |
|---|---|
| `View` | Independent left/right viewer sources |
| `Segmentation` | Strategy, connectivity, area/border limits |
| `LocalBackground` | Buffer and background neighborhood rules |
| `Display`, `Colormaps`, `Palettes` | General appearance and named color choices |
| `AzimuthDisplay`, `ObjectDisplay`, `ObjectSelection` | Image/object appearance and crop preferences |
| `ScatterPlot`, `SwarmPlot`, `PolarHistogram`, `ObjectIntensityProfile` | Plot options and variable selection |
| `Clustering` | Features and clustering parameters |
| `IO` | Import/export preferences |

Mask strategy is selected through `settings.Segmentation.Strategy`. These options
are configuration for subsequent processing/UI increments, not implementations
of those algorithms or UI features. Runtime zoom state, old tabs/views, graphics
handles, and reference-image settings are omitted. Colormaps and palettes are
stored by name instead of serializing legacy helper objects.

Subsettings emit domain events and `Changed`; the root forwards both with
`Domain`, `Name`, `OldValue`, and `NewValue`, matching DesmoSTORM. Save app defaults
with `settings.save()`, load with `oops.config.Settings.load()`, and reset with
`oops.config.Settings.restore()`. Projects currently hold settings in memory;
project-file persistence is deferred. The single `oops.app.GUI` controller owns
UI listeners and settings-change callbacks.

Logging uses a session facade over `matlabx.logging.Logger`, independently of
project settings. Command-window output starts lazily with the first log message.
Enable file logging explicitly:

```matlab
[logger, logPath] = oops.Log.startSession(); % timestamped file under logs/
oops.Log.INFO("Ready");
oops.Log.DEBUG("Detailed diagnostic"); % stored/file output; hidden from command window
% oops.Log.EXCEPTION(ME) forwards a caught exception, including identifier/stack.
oops.Log.close(); % flush pending entries and close the file
```

Use `WriteFile=false` for a command-window-only session, or specify
`LogFile="path/to/session.log"`. `oops.Log.configure(matlabx.config.Logging(...))`
changes session policy. Normal command-window output begins at INFO; file output
includes DEBUG messages and exception details. The underlying logger can accept
the controller's textarea UI sink. Runtime operation boundaries log caught exceptions and rethrow
them to preserve identifiers and stacks; validation helpers use explicit errors
rather than assertions. Method headers document these APIs in the DesmoSTORM
style. Legacy code and the vendored dependency retain their existing conventions.

Run the foundation checks with:

```matlab
results = runtests("tests/foundation");
assertSuccess(results);
```

### First UI pass

From the repository root, launch the new application with:

```matlab
ui = oops.launch(); % the output is optional; a second call focuses this window
```

The left matlabx accordion begins with Groups, Images, and Objects. Highlight a
node to make it active; check boxes to build an independent batch selection.
Active/selected state is owned by the model as IDs. Projects remember their
active group, groups their active image, and images their active object, so
switching parents restores the previous child. Batch selections also survive
navigation. Project save/load remains deferred.

Create groups through the Groups tree context menu. Node menus delete exactly
the context-clicked group/image/object; separate commands delete checked sets.
Import images through File > Load images. Individual object display is deferred.
The two ImageAxes reuse their graphics as the View dropdowns change sources:
Input, Calibration, Corrected, Average intensity, Mask, Order, and Azimuth. Defaults are Input on the
left and Corrected on the right. Viewer panel interiors follow the available
width plus calibrated ImageAxes title chrome; the viewer area does not scroll.
The log panel spans both viewers below them.

View menu presets set both accordion dropdowns together: Files shows Input and
Calibration; Mask, Order, and Azimuth show Average intensity on the left and the
corresponding result on the right. Average intensity uses corrected frames when
available and otherwise raw input. Preset definitions in `oops.app.viewPresets`
contain panel content descriptions, with graphics owned by the controller.

Both viewers include Mask, Overlays, Polygon, and RectangleSelect tools. Committed
image masks are supplied to matching-size sources and can be toggled independently
in each viewer. Each object has one polygon, keyed by its model ID, with exact
exterior pixel-edge boundaries. Geometry comes from
`oops.geometry.objectBoundary`, using the original OOPS eight-connected,
`noholes` tracing on each object's own crop. Segmentation connectivity continues
to define object membership; hole rendering and complex corner contacts are
deferred. Clicking
activates an object; shift-click or rectangle selection changes its independent
batch selection. Viewer state, tree highlights/checks, and model IDs stay in sync.
Deleting a polygon or using the Objects tree deletion menu removes the object and
its mask pixels. `image.removeObjects(ids)` exposes the same operation without UI;
surviving IDs and measurements are preserved. Rerunning segmentation creates a
new object collection. Navigation/selection updates reuse existing polygons. Polygon deletion requests
are committed as one model batch before overlays change. Both viewers reconcile
through `removeMany`; surviving tree nodes, menus, polygons, and model listeners
are retained. Deletion refreshes the mask source and viewer masks without reading
intensity stacks or recalculating display-limit controls.

The Display Limits accordion has separate project-wide automatic scaling toggles
for Intensity and Order. User ranges live on each image and survive toggling auto
scaling. One intensity range is shared by all four angles and the Input/Corrected
and Average intensity sources. Automatic intensity scaling uses their combined finite values; automatic
ranges use the 1st/99th percentiles with a nondegenerate fallback. Calibration,
Mask, and Azimuth retain their fixed ranges. Slider dragging previews limits;
release stores them and turns off automatic scaling only for that domain.
Programmatically, use `image.setDisplayRange("Intensity", [low high])` or
`image.setDisplayRange("Order", [low high])`. These values are model state;
project-file save/load remains deferred.

Mask controls follow processing order: strategy/connectivity, strategy-specific
adjustment, then **Object filtering** (minimum area, maximum objects, border width).
The Puncta threshold slider uses one thumb in [0,1] on the normalized enhanced
image. It appears only for Puncta; run segmentation before adjusting it. Dragging
previews the final mask without changing object membership, and release commits
an image-local manual threshold. Reset to automatic restores Otsu. The maximum
object count never changes the threshold: after size/border filtering, retain
the brightest N components by mean corrected input intensity (raw input when
uncalibrated). Zero disables the count limit; ties follow component order.

`oops.analysis.segment.strategies` is the small strategy catalog: names/labels,
algorithm and optional preview functions, and parameter names/defaults/ranges/
adjustability. An empty parameter default requests automatic determination.
Algorithms are separate ordinary functions. Each analyzed image stores one
`oops.analysis.segment.Parameters` value in `image.SegmentationParameters`.
It captures strategy, common filters, applied values, automatic values, explicit
automatic/manual provenance, and candidate/retained counts. Project setting edits
affect subsequent runs without rewriting existing recipes. Upstream correction
clears the recipe with its obsolete mask. The analyzer's `adjustSegmentation`
method is also accessible without a GUI.

The Colormap accordion uses an Intensity/Order/Azimuth dropdown and a tree of
matlabx registry categories/maps. Each domain retains its own name/category.
`settings.Colormaps.setMap(domain, name, category)` commits both together.
Azimuth uses the legacy OOPS circularization bridge. Its ImageAxes data remains
scalar degrees in [0,180), allowing pixel inspection; stored `image.Azimuth`
remains radians, counterclockwise from image X. `oops.render.source` prepares
these display/export sources without changing model results. Calibration view
shows the normalized mean of the parent group's assigned calibration stacks.

Physical X/Y size and units come from each input's OME metadata and are retained
in `image.PixelSize` (`X`, `Y`, `UnitX`, `UnitY`); missing axes use 1 px. Distance
and area measurements remain in pixels internally. There is no project-wide
Analysis/pixel-size setting. Object Display and Local Background settings remain
available programmatically but have no user-facing accordion items.

Check the target groups before File > Load calibration stacks for selected
groups. Files are registered once at the project level and groups reference
registry IDs. The supplied set replaces each checked group's assignment, and
correction runs automatically. Reimporting the same file/series reuses its
registry entry. Stack geometry is validated before assignments change. New
images added to an already calibrated group are corrected automatically.
Correction averages calibration replicates and normalizes using a single maximum
across all four planes, preserving relative polarization response as in legacy
OOPS. Zero calibration values produce NaN corrected samples. A new correction
invalidates dependent masks, objects, and FPM results.

The Analysis menu runs segmentation and order/orientation statistics. Targets
are checked images across the project, otherwise all images of checked groups,
otherwise the active image. Segmentation uses the configured strategy and 4/8
connectivity (default 4). Puncta retains opening/median/Otsu enhancement and the
area, border, and object-count controls. Filaments uses ridge enhancement and
long-line openings; the legacy branch/midline machinery is deferred. FPM uses
orthogonal intensity differences normalized by half the total intensity, with
order clipped to [0,1]. Zero-total/invalid pixels have NaN order and azimuth;
zero-modulation pixels have zero order and undefined azimuth. Missing calibration
logs a warning and processing proceeds with raw planes.

The Analyzer delegates algorithms to the analysis package, commits results, and
updates scalar object morphology, intensity/background, order, and axial angle
summaries. `Mask` is stored directly; `Corrected`, `Order`, and `Azimuth` expose
numeric arrays in `image.Results` without duplicating storage. Object geometry
remains defined by the mask partition. Processing settings configure the next
explicit run. Optional progress accepts a dialog or `(message, fraction)` callback.
Plots, annotations, and reference images remain deferred.
Save/load app defaults through the Settings menu or the existing settings API.

The controller accepts an existing project, and importing is also accessible
without the file chooser:

```matlab
oops.setup.run();
project = oops.model.Project("Experiment");
ui = oops.app.GUI(Project=project); % close the existing window first
ui.addGroup("Condition A");
images = ui.addFiles(["replicate1.tif", "replicate2.tif"]);
```

Headless processing uses the same facade:

```matlab
cal = project.addCalibration(oops.io.readInput("flat-field.tif"), "Flat field");
oops.analysis.Analyzer.assignCalibrations(project, project.Groups, cal.ID);
oops.analysis.Analyzer.segmentImages(images, project.Settings);
oops.analysis.Analyzer.analyzeImages(images, project.Settings);
```

Models only store data/relationships and emit events. When a GUI is open, its
controller observes direct `group.setCalibrations(ids)` changes and corrects that
group automatically. For headless work use `Analyzer.assignCalibrations`, which
performs preflight and correction itself.

The default UI launch creates a timestamped file log under `logs/`. Closing the
UI detaches its sink and closes its owned logger. A supplied project survives UI
closure. `oops.app.hasMainFigure()`, `getMainFigure()`, and `focusMainFigure()`
provide the same convenience as DesmoSTORM.

Version control is centralized in `oops.Info`; this development release is
`2.0.0`. The counters are intentionally independent:

| Marker | Bump when |
| --- | --- |
| `Version` | Releasing a new application version |
| `RequiredSetupVersion` | Launch must repeat installation/setup checks |
| `SettingsSchemaVersion` | Saved settings change shape or meaning |
| `FactoryDefaultsVersion` | App-level settings should adopt an explicit new generation of defaults |
| `ProjectSchemaVersion` | The project layout changes for future project-file persistence |

`oops.Version.compare` compares numeric major/minor/patch components; `2.0` and
`2.0.0` compare equally. New projects carry application and project-schema
metadata. Project-file save/load remains deferred.

Settings snapshots include application, schema, and factory-default markers.
`Settings.fromStruct` applies schema migration while preserving stored values.
`Settings.load` additionally applies versioned factory-default changes to app
JSON files and saves successful migrations. The first 2.0 defaults generation
refreshes tunable defaults while retaining `IO.DefaultFolder`, matching
DesmoSTORM. The original JSON is retained as
`settings.json.before-2.0.0.bak` before the refresh. Unsupported newer settings
schemas/default generations fail without rewriting the file. Future migrations
belong in the separate schema/default stages in `Settings`; an app-version bump
alone does not reset settings.

Launch compares the stored `SetupVersion` preference with
`Info.RequiredSetupVersion` and records the marker after successful setup.
Session paths, Bio-Formats, and cached UI services are initialized each new launch
even when full setup is already current.

Persistent session preferences are separate from project settings:

```matlab
oops.Preferences.describe();
oops.runtime.enableDeveloperMode(); % immediately applies DEBUG logging defaults
oops.runtime.disableDeveloperMode();
oops.Preferences.set("LoggingUILevel", "WARN");
oops.Log.applyConfigFromPreferences();
```

Explicit logging preferences override normal/developer defaults. Runtime helpers
also accept `ApplyLogging=false` and `Verbose=false`. Tests restore any existing
preferences after checking these APIs.

Run both foundation and real-control UI checks in MATLAB R2026b:

```matlab
results = runtests({"tests/foundation", "tests/ui"});
assertSuccess(results);
```


Threshold adjustment commits use the cached enhanced image and the saved
automatic threshold, matching the live preview filters. Local S/B rings are
computed within padded object crops; a shared buffer mask excludes neighboring
objects' buffers. Controller reconciliation refreshes the tree and polygon
registries once while preserving intensity/FPM image data and display limits.
INFO logging reports input loading and the main calibration, segmentation, FPM,
and measurement stages without per-object messages.

### matlabx subtree

matlabx is a squashed Git subtree under `external/matlabx`, initially pinned
to `2804e5c0714047c1bb9166bc2b6407a3ef0d3895`, the same revision vendored by
DesmoSTORM at the start of this rewrite. It is now updated to remote `main` at
`0d570fa41fe1f84cba760206d55362ca9807508a`. Preserve its licenses and notices.
Update the dependency through the subtree workflow rather than editing vendored
files directly:

```sh
git subtree pull --prefix=external/matlabx https://github.com/will-f-dean-36/matlabx.git main --squash
```

`oops.setup.run()` follows DesmoSTORM's modular startup sequence:
`oops.setup.setupSearchPath()` adds the OOPS and bundled matlabx roots;
`oops.setup.matlabx()` initializes matlabx dependency paths, Bio-Formats, and
optional cached UI calibration; then saved OOPS settings are loaded/validated.
Each setup helper is independently callable. Setup uses session-local paths by
default; `oops.setup.run(SavePath=true)` persists the complete search path after
all dependency paths have been initialized. UI calibration is opt-in with
`UI=true` and enabled by `oops.launch()`. For in-memory-only work, use
`oops.setup.run(BioFormats=false)`. Development and verification use MATLAB R2026b.
