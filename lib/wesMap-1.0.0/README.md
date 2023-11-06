# wesMap
 Wes Anderson themed colormap generator for MATLAB

Inspired by Patrick Rafter (https://www.prafter.com/color) and Karthik Ram https://github.com/karthik/wesanderson.

Original colormaps are replicated from Patrick Rafter.

## Installation

To install, copy the `wesMap` folder to your computer and add it to your MATLAB path: 
1. Navigate to MATLAB->Home->Set path
2. 'Add folder...' and select the wesMap folder. You do not need to include the colormap generator subfolder folder.
3. Save and close

## Use

The function `wesMap(map_name, num_colors)` function takes a required `map_name` and optional `num_colors` input. `map_name` is a string with the name of the desired colormap: see below for options. `num_colors` is the optional desired number of colors to discretize the map to. 

### Discrete colors

Use `num_colors` in place of the `colormap name(number)` functionality for MATLAB default colomaps. I.e., `colormap parula(5)` could be replaced with `colormap wesMap('Isle',5)`

### Reverse colors

Use MATALBs `flipud(A)` function, i.e., `colormap flipud(wesMap('Isle'))`

### Colormaps

11 colormaps are included: 

`Budapest`, `Calvacanti`, `Chevalier`, `Darjeeling`, `Fox`, `Isle`, `MoonriseSam`, `MoonriseSuzy`, `Rushmore`, `Tenenbaums`, `Zissou`

![wesMap color key](/assets/wesMap_color_key.tif)

