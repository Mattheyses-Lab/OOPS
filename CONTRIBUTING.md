# Contributing to matlabx

matlabx is under active development, and APIs may still move as the library
settles. Contributions should favor small, focused changes that preserve the
existing MATLAB package structure and keep reusable library code independent
from downstream app-specific assumptions.

## Setup

Clone the repository, add the repository root to the MATLAB path, and run the
setup helper:

```matlab
addpath('/path/to/matlabx')
matlabx.setup.run()
```

For a lighter setup, run individual setup steps as needed:

```matlab
matlabx.setup.searchPath()
matlabx.setup.bioFormats()
matlabx.setup.uiCalibration()
```

## Development Guidelines

- Keep changes scoped to the feature or bug being addressed.
- Prefer package names and class names that are descriptive, MATLAB-friendly,
  and consistent with the existing `matlabx` organization.
- Keep public APIs small and documented.
- Add method help headers in MATLAB files so `help`, `doc`, and editor hints
  remain useful.
- Preserve existing app-facing behavior unless an API change is intentional.
- Avoid adding third-party code or data without also updating `NOTICE`,
  `LICENSE` references, and any required attribution.
- Do not commit machine-local state, generated calibration files, `.asv` files,
  `.DS_Store`, or other editor/OS artifacts.

## Checks

Before committing MATLAB code changes, run targeted checks where practical:

```matlab
checkcode("path/to/file.m")
```

For UI or image-display changes, also run a small smoke test in MATLAB. Useful
examples include:

```matlab
I = matlabx.image.Image5D.demo();
ax = matlabx.app.quickshow(I);

matlabx.ui.interaction.demos.HubEventDemo()

app = matlabx.app.PointClusterTuner();
```

When touching colormaps, image loading, or Bio-Formats integration, verify that
the relevant data can be discovered and loaded without relying on machine-local
paths outside the repository.

## Licensing And Notices

matlabx is licensed under GPL-2.0-or-later. New matlabx-owned source files
should include the project GPL header used throughout the repository.

Bundled third-party code, data, lookup tables, colormaps, and binary assets
must retain their upstream license files when available and be documented in
`NOTICE`. When a map or dataset can be generated from the user's installed
MATLAB rather than redistributed, prefer runtime generation.

## Commit Style

Use short, imperative commit messages:

```text
Add rectangle overlay resizing
Fix ImageAxes display limit syncing
Document runtime MATLAB colormaps
```

For larger work, commit in coherent chunks so downstream projects can update
and debug changes more easily.
