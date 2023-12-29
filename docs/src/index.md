```@meta
CurrentModule = RemoteSensingToolbox
```

# RemoteSensingToolbox

[RemoteSensingToolbox](https://github.com/JoshuaBillson/RemoteSensingToolbox.jl) is a pure Julia package built on top of [Rasters.jl](https://github.com/rafaqz/Rasters.jl) for visualizing, analyzing, and manipulating remotely sensed imagery. Most methods expect either an `AbstractRaster` or `AbstractRasterStack` as input and return the same. The most important exception to this rule is [`visualize`](@ref), which returns an `Array` of either `Gray` or `RGB` pixels, depending on whether the visualization is intended to be in color or grayscale. The result is that the output of `visualize` will be automatically displayed inside `Pluto`. 

# Features

`RemoteSensingToolbox` is a work in progress. This means that new features are being added and existing features are subject to change. To contribute to this project, please create an issue on [GitHub](https://github.com/JoshuaBillson/RemoteSensingToolbox.jl) or open a pull request.  A summary of both existing and future features are provided below:

| Feature                   | Description                                                  | Implemented        |
| :------------------------ | :----------------------------------------------------------- | :----------------: |
| Visualization             | Visualize images with various band composites                | Yes                |
| Land Cover Indices        | Calculate indices such as MNDWI and NDVI                     | Yes                |
| QA and SCL Decoding       | Decode Quality Assurance and Scene Classification masks      | Yes                |
| Pixel Masking             | Mask pixels to remove objects such as clouds or shadows      | Yes                |
| PCA                       | Perform PCA analysis, transformation, and reconstruction     | Yes                |
| MNF                       | Minimum Noise Fraction transformation and reconstruction     | Yes                |
| Signature Analysis        | Visualize spectral signatures for different land cover types | Yes                |
| Land Cover Classification | Exposes an `MLJ` interface for classifying land cover types  | No                 |
| Endmember Extraction      | Extract spectral endmembers from an image                    | No                 |
| Spectral Unmixing         | Perform spectral unmixing under a given endmember library    | No                 |


# Rasters.jl

`RemoteSensingToolbox` is intended to be used in conjunction with the wider Julia ecosystem and as such, seeks to avoid duplicating functinalities provided by other packages. As the majority of methods accept and return `AbstractRaster` or `AbstractRasterStack` objects, users should be able to call methods from [Rasters.jl](https://github.com/rafaqz/Rasters.jl) at any point in the processing pipeline. A summary of common functionalities offered by `Rasters` is provided below: 

| **Method**                          | **Description**                                                                        |
| :---------------------------------- | :------------------------------------------------------------------------------------- |
| `mosaic`                            | Join rasters covering different extents into a single array or file.                   |
| `crop`                              | Shrink objects to specific dimension sizes or the extent of another object.            |
| `extend`                            | Extend objects to specific dimension sizes or the extent of another object.            |
| `trim`                              | Trims areas of missing values for arrays and across stack layers.                      |
| `resample`                          | Resample data to a different size and projection, or snap to another object.           |
| `mask`                              | Mask a raster by a polygon or the non-missing values of another Raster.                |
| `replace_missing`                   | Replace all missing values in a raster and update missingval.                          |
| `extract`                           | Extract raster values from points or geometries.                                       |
| `zonal`                             | Calculate zonal statistics for a raster masked by geometries.                          |


# Satellites

`AbstractSatellites` are Julia types that encode sensor-specific information needed for many methods in `RemoteSensingToolbox`
to work without requiring tedious details from the end user. One of their primary uses is to allow various layers to be requested 
by name. For example, if we have bound the variable `src` to an instance of `Landsat8`, then we can load a cloud mask from the 
included QA file by calling `Raster(src, :clouds)`. Each `AbstractSatellite` also includes information about how to convert
digital numbers into reflectance or temperature, the wavelengths associated with each band, and how to parse metadata from a scene's name.

```@docs
AbstractSatellite
Landsat7
Landsat8
Landsat9
Sentinel2
DESIS
bands
layers
wavelengths
wavelength
blue_band
green_band
red_band
nir_band
swir1_band
swir2_band
dn_scale
dn_offset
decode
encode
Rasters.Raster
Rasters.RasterStack
```

# Visualization

Remotely sensed imagery is typically encoded as either `UInt16` or `Int16` values. However, many products only actually use the first 12 bits for storing information. The result is that naive visualization methods will produce a near-black image, since the maximum possible brightness will be located in the lower range of values provided by the 16 bit encoding. To address this, we need to perform a linear stretch before visualizing an image. Moreover, many satellites have more than three bands, which motivates the use of band combinations to emphasize certain features and land cover types.

```@autodocs
Modules = [RemoteSensingToolbox]
Pages = ["visualization.jl"]
Private = false
```

# Land Cover Indices

Land cover indices are used to highlight different types of land cover. For example, the Modified Normalized Difference Water 
Index (MNDWI) is used to highlight water while diminishing built-up areas. Each index is expressed as a function of two or more 
bands. `RemoteSensingToolbox` can automatically select the appropriate bands for a given index by providing an `AbstractSatellite`. 
We also provide lower-level variants to enable the use of unsupported satellites.

```@autodocs
Modules = [RemoteSensingToolbox]
Pages = ["indices.jl"]
Private = false
```

# Spectral Analysis

Spectral analysis involves studying the relationships between different materials and their corresponding spectral signatures. Due to the interactions between light and matter, each signature is unique to the material that emitted it. We can exploit this fact to assign a label to each pixel, or even estimate the abundances of different materials at a sub-pixel level.

```@docs
extract_signatures
plot_signatures
plot_signatures!
```

# Principal Component Analysis

Principal Component Analysis (PCA) is typically used to reduce the dimensionality of data. In the case of remote sensing, we are interested in reducing the number of bands we need to store while retaining as much information as possible. PCA rotates the bands into a new coordinate space where each band, called a principal component, is orthogonal to and uncorrelated with every other component. By convention, we order the bands in the transformed image in terms of their explained variance, such that the nth component accounts for more variance than any component after it.

```@autodocs
Modules = [RemoteSensingToolbox]
Pages = ["pca.jl"]
Private = false
```

# Minimum Noise Fraction

The Minimum Noise Fraction (MNF) transformation is used to separate noise from data along the spectral dimension. This method is typically used with hyperspectral imagery, both as a means of dimension reduction and for noise removal. The transformed image will have its bands placed in descending order according to their Signal to Noise Ratio (SNR). The result is that the noise becomes concentrated in the higher bands, which can then be removed by either applying a standard image denoising algorithm or dropping them altogether.

```@autodocs
Modules = [RemoteSensingToolbox]
Pages = ["mnf.jl"]
Private = false
```

# Utilities

`RemoteSensingToolbox` provides several utility functions for modifying and processing remotely sensed data.

```@autodocs
Modules = [RemoteSensingToolbox]
Pages = ["utils.jl"]
Private = false
```