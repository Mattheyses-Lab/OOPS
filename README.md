# Object-Oriented Polarization Software (OOPS)

[![version: v1.0.0](https://img.shields.io/badge/version-v1.0.0-green)](https://github.com/Mattheyses-Lab/OOPS/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A GUI-based MATLAB software package for object-oriented analysis of excitation-resolved, widefield fluorescence polarization microscopy (FPM) data. 

The ultimate goal of the software is to retrieve pixel-by-pixel order and orientation statistics. We refer to these throughout as:
- Order Factor (OF) - in-plane orientational order of all the dipoles in a single pixel
- Azimuth - ensemble average direction of the dipoles in each pixel, as projected into the sample plane

To calculate pixel-by-pixel OF and azimuth, you will need:
- (**required**) 4-image FPM stack(s), where individual images were captured using excitation polarizations of 
0°, 45°, 90°, and 135° (counter-clockwise with respect to the horizontal direction in the image)
- (optional) 4-image flat-field stack(s) captured at the same excitation polarizations

For a more detailed description of our imaging setup and calculations, please see: 
[Defining domain-specific orientational order in the desmosomal cadherins](https://www.sciencedirect.com/science/article/pii/S0006349522008293).

## Installation and usage

This software has only been fully tested in MATLAB version `R2023a`. It is not guaranteed to work with any previous versions.

OOPS makes use of several libraries sourced from the [MATLAB File Exchange](https://www.mathworks.com/matlabcentral/fileexchange/) or elsewhere, each of which are subject to their own licenses. These libraries are included with the source in the `lib` directory, so you do not have to download them yourself. However, if you intend to use this software, read the documentation for each library to ensure that your desired use is permitted. The versions included with OOPS may or may not be the latest versions. If you update these libraries yourself, the software is not guaranteed to work. Links to each library can be found in the [Sources](#sources) section.

OOPS also relies on several MATLAB toolboxes which you will need to manually add to MATLAB. Links to each toolbox can also be found in the [Sources](#sources) section.

To install this software, dowload the lasest [release](https://github.com/Mattheyses-Lab/OOPS/releases), unzip it, and make sure all associated files/folders are on the MATLAB `PATH`. For help, see [here](https://www.mathworks.com/help/matlab/matlab_env/add-remove-or-reorder-folders-on-the-search-path.html).

Once you have downloaded the software and required toolboxes, you can start up the GUI by simply typing `OOPS` in the command window.




## Analysis pipeline and data structure

OOPS allows for object-based analyses of FPM data across multiple experimental conditions. The GUI is designed to 
provide interactive user control over each step of the FPM analysis pipeline. To calculate pixel-by-pixel OF and azimuth, only a few steps are required. 
Thus, depending on your desired analysis, certain steps in the pipeline can be skipped. Schematics showing the processing pipeline and data structure are shown below.

![OOPS flowchart and data structure](/assets/images/examples/FlowchartAndDataStructure.png)

## Customization options

The GUI was designed with flexibility in mind and enables customization of various processing steps and display options. 
Examples of the customization offered are given below:
- Segmentation
  - Built-in segmentation schemes
  - Design and save custom segmentation schemes with `CustomMaskMaker.m`
  - Ability to upload image masks generated elsewhere
- Order Factor (OF) image
  - Raw OF
  - Masked OF image
  - OF-intensity RGB overlay
- Azimuth image
  - Raw azimuth
  - Masked azimuth
  - Azimuth-intensity RGB overlay
  - Azimuth-OF-intensity HSV overlay
- Azimuth stick plot intensity overlay
  - Color sticks by direction (azimuth), magnitude (OF), or user-selected color
  - Customize line length, width, number, and transparency
- Azimuth polar histogram
  - Set number of polar bins
  - Color bin wedges by direction, counts, or user-selcted color
- Object labeling/filtering
  - Select, label, and/or delete individual objects manually
  - Label objects automatically with k-means clustering
  - Filter objects by designing object property filters
  - Manage object labels - set label color, merge labels
- Object swarm plots
  - Plot any object property
  - Group plots by experimental condition, object label, or both
  - Color plots by group or magnitude
  - Adjust plot background, foreground, and error bar colors

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

#### MATLAB Toolboxes

- [Image Processing Toolbox](https://www.mathworks.com/products/image.html)
- [Parallel Computing Toolbox](https://www.mathworks.com/products/parallel-computing.html)
- [Signal Processing Toolbox](https://www.mathworks.com/products/signal.html)
- [Statistics and Machine Learning Toolbox](https://www.mathworks.com/products/statistics.html)
- [Curve Fitting Toolbox](https://www.mathworks.com/products/curvefitting.html)
