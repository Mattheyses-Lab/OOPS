# Object-Oriented Polarization Software (OOPS)

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

To open OOPS, simply type the following into the MATLAB command window.

`OOPS`

