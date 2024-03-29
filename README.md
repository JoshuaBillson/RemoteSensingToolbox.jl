# RemoteSensingToolbox

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JoshuaBillson.github.io/RemoteSensingToolbox.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JoshuaBillson.github.io/RemoteSensingToolbox.jl/dev/)
[![Build Status](https://github.com/JoshuaBillson/RemoteSensingToolbox.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JoshuaBillson/RemoteSensingToolbox.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/JoshuaBillson/RemoteSensingToolbox.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JoshuaBillson/RemoteSensingToolbox.jl)


[RemoteSensingToolbox](https://github.com/JoshuaBillson/RemoteSensingToolbox.jl) is a pure Julia package built 
on top of [Rasters.jl](https://github.com/rafaqz/Rasters.jl) for reading, visualizing, and processing remotely 
sensed imagery. Users may refer to the Tutorials section in the 
[docs](https://JoshuaBillson.github.io/RemoteSensingToolbox.jl/stable/) for examples on how to use this package.

# Installation

To install this package, first start the Julia REPL and then open the package manager by typing `]`.
You can then download `RemoteSensingToolbox` directly from the official Julia repository like so:

```
(@v1.9) pkg> add RemoteSensingToolbox
```

Once `RemoteSensingToolbox` has been installed, you can import it like any other Julia package. Please
note that many features require you to also import the `Rasters` package.

```julia
using RemoteSensingToolbox, Rasters
```

# Features

This package is a work in progress, which means that new features are being added and existing features 
are subject to change. To contribute, please create an issue on 
[GitHub](https://github.com/JoshuaBillson/RemoteSensingToolbox.jl) or open a pull request. A summary of both 
existing and planned features is provided below:

| Feature                   | Description                                                  | Implemented        |
| :------------------------ | :----------------------------------------------------------- | :----------------: |
| Reading and Writing       | Read layers from a scene and the write results to disk       | :white_check_mark: |
| Visualization             | Visualize images with various band composites                | :white_check_mark: |
| Land Cover Indices        | Calculate indices such as MNDWI and NDVI                     | :white_check_mark: |
| QA and SCL Decoding       | Decode Quality Assurance and Scene Classification masks      | :white_check_mark: |
| Pixel Masking             | Mask pixels to remove objects such as clouds or shadows      | :white_check_mark: |
| PCA                       | Perform PCA analysis, transformation, and reconstruction     | :white_check_mark: |
| MNF                       | Minimum Noise Fraction transformation and reconstruction     | :white_check_mark: |
| Signature Analysis        | Visualize spectral signatures for different land cover types | :white_check_mark: |
| Land Cover Classification | Exposes an `MLJ` interface for classifying land cover types  | :x:                |
| Endmember Extraction      | Extract spectral endmembers from an image                    | :x:                |
| Spectral Unmixing         | Perform spectral unmixing under a given endmember library    | :x:                |


# Rasters.jl

`RemoteSensingToolbox` is intended to be used in conjunction with the wider Julia ecosystem and as such, seeks to avoid duplicating functinalities provided by other packages. As the majority of methods accept and return `AbstractRaster` or `AbstractRasterStack` objects, users should be able to call methods from [Rasters.jl](https://github.com/rafaqz/Rasters.jl) at any point in the processing pipeline. A summary of common functionalities offered by `Rasters.jl` is provided below: 

| **Method**             | **Description**                                                                        |
| :--------------------- | :------------------------------------------------------------------------------------- |
| `mosaic`               | Join rasters covering different extents into a single array or file.                   |
| `crop`                 | Shrink objects to specific dimension sizes or the extent of another object.            |
| `extend`               | Extend objects to specific dimension sizes or the extent of another object.            |
| `trim`                 | Trims areas of missing values for arrays and across stack layers.                      |
| `resample`             | Resample data to a different size and projection, or snap to another object.           |
| `mask`                 | Mask a raster by a polygon or the non-missing values of another Raster.                |
| `replace_missing`      | Replace all missing values in a raster and update missingval.                          |
| `extract`              | Extract raster values from points or geometries.                                       |
| `zonal`                | Calculate zonal statistics for a raster masked by geometries.                          |

# Quickstart Example

Typically, the first step in a workflow is to read the desired layers from disk. To do so, we first need to place
our product within the appropriate context; in this case `Landsat8`. With this done, we can load whichever
layers we desire by simply requesting them by name. A complete list of all available layers can be acquired by
calling `layers(Landsat8)`. We typically use a `Raster` to load a single layer, while a `RasterStack` is used 
to load multiple layers at once. By default, `RasterStack` will read all of the band layers when none are
specified. We can also set `lazy=true` to avoid reading everything into memory up-front.

```julia
using RemoteSensingToolbox, Rasters

# Read Landsat Bands
src = Landsat8("data/LC08_L2SP_043024_20200802_20200914_02_T1")
stack = RasterStack(src, lazy=true)
```

Now let's visualize our data to see what we're working with. The `true_color` method uses the red, green, and
blue bands to produce an image that is familiar to the human eye. In most other frameworks, we would have to specify
each of these bands individually, which in turn requires knowledge about the sensor in question. However, because
we have placed our scene within a `Landsat8` context, `true_color` is smart enough to figure this out on its own.
As an alternative, we could have also called `true_color(Landsat8, stack; upper=0.90)`, which requires passing in
the sensor type as the first agument and a `RasterStack` containing the required bands as the second. Many 
other methods in `RemoteSensingToolbox` follow this same pattern.

```julia
true_color(src; upper=0.90)
```

![](https://github.com/JoshuaBillson/RemoteSensingToolbox.jl/blob/main/docs/src/figures/true_color.jpg?raw=true)

You may have noticed that we set the keyword `upper` to 0.90. This parameter defines the upper quantile that 
is used during histogram adjustment and is set to 0.98 by default. However, the presence of bright clouds
requires us to lower it in order to prevent the image from appearing too dark. We can remove these clouds by
passing the cloud and cloud shadow masks into the `apply_masks` method. As with other layers, we can simply 
request them by name.

```julia
# Mask Clouds
cloud_mask = Raster(src, :clouds)
shadow_mask = Raster(src, :cloud_shadow)
masked = apply_masks(stack, cloud_mask, shadow_mask)

# Visualize in True Color
true_color(Landsat8, masked)
```

![](https://github.com/JoshuaBillson/RemoteSensingToolbox.jl/blob/main/docs/src/figures/masked.jpg?raw=true)

Now let's try to visualize some other band combinations. The `Agriculture` band combination is commonly used to 
emphasize regions with healthy vegetation, which appear as various shades of green.

```julia
agriculture(src; upper=0.90)
```
![](https://github.com/JoshuaBillson/RemoteSensingToolbox.jl/blob/main/docs/src/figures/agriculture.jpg?raw=true)

We'll finish this example by computing a few different land cover indices. Each index expects two bands as input, 
such as green and swir (MNDWI), red and nir (NDVI), or nir and swir (NDMI). As with visualization, we do
not need to specify these bands manually so long as the sensor type is known. In general, each index has 
three forms: one that requires only a single `AbstractSatellite` instance, a second that expects both the type 
of satellite and a `RasterStack`, and a third which expects a `Raster` for each band.

```julia
# Extract Region of Interest
roi = @view masked[X(5800:6800), Y(2200:3200)]

# Calculate Indices
indices = map(visualize, [mndwi(Landsat8, roi), ndvi(Landsat8, roi), ndmi(Landsat8, roi)])

# Visualize
tc = true_color(Landsat8, roi; upper=0.998)
mosaic = mosaicview([tc, indices...]; npad=10, fillvalue=0.0, ncol=2, rowmajor=true)
```

![](https://github.com/JoshuaBillson/RemoteSensingToolbox.jl/blob/main/docs/src/figures/indices.jpg?raw=true)

For more examples, refer to the [docs](https://JoshuaBillson.github.io/RemoteSensingToolbox.jl/stable/).