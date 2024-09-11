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

For more detailed information about out imaging setup and calculations, also see:
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
