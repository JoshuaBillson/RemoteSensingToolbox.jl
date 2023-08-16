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


# Bandsets

Bandsets are Julia types that encode the sensor-specific information needed for many methods in `RemoteSensingToolbox` to work without the need for tedious details from the end user. Such methods typically expect the sensor type to be passed in as the first argument, which then triggers Julia's multiple dispatch to execute the appropriate sensor-specific procedures. Bandsets are provided for several common sensors including Sentinel-2, Landsat 7, and Landsat 8.

| **Method**                  | **Description**                                                                          |
| :-------------------------- | :--------------------------------------------------------------------------------------- |
| [`bands`](@ref)             | Return the band names in order from shortest to longest wavelength.                      |
| [`wavelengths`](@ref)       | Return the central wavelengths for all bands from shortest to longest.                   |
| [`wavelength`](@ref)        | Return the central wavelength for the specified band.                                    |
| [`blue`](@ref)              | Return the blue band for the given sensor.                                               |
| [`green`](@ref)             | Return the green band for the given sensor.                                              |
| [`red`](@ref)               | Return the red band for the given sensor.                                                |
| [`nir`](@ref)               | Return the nir band for the given sensor.                                                |
| [`swir1`](@ref)             | Return the swir1 band for the given sensor.                                              |
| [`swir2`](@ref)             | Return the swir2 band for the given sensor.                                              |
| [`read_bands`](@ref)        | Read bands from the specified directory into a `Raster` or `RasterStack`.                |
| [`read_qa`](@ref)           | Reads the QA or scene classification file from the provided file or directory.           |
| [`dn_to_reflectance`](@ref) | Decodes digital numbers to reflectance.                                                  |


```@docs
AbstractBandset
DESIS
Landsat8
Landsat7
Sentinel2
red
green
blue
nir
swir1
swir2
bands
wavelengths
wavelength
parse_band
read_bands
read_qa
dn_to_reflectance
```

# Visualization

Remotely sensed imagery is typically encoded as either `UInt16` or `Int16` values. However, many products only actually use the first 12 bits for storing information. The result is that naive visualization methods will produce a near-black image, since the maximum possible brightness will be located in the lower range of values provided by the 16 bit encoding. To address this, we need to perform a linear stretch before visualizing an image. Additionally, many satellites have more than three bands, which motivates the use of band combinations to emphasize certain features and land cover types.

| **Method/Type**             | **Description**                                                                          |
| :-------------------------- | :--------------------------------------------------------------------------------------- |
| [`TrueColor`](@ref)         | The true color band combination produces RGB images that are familiar to the human eye.  |
| [`Agriculture`](@ref)       | Used for crop monitoring and emphasizing healthy vegetation.                             |
| [`Geology`](@ref)           | Emphasizes geological formations, lithology features, and faults.                        |
| [`ColorInfrared`](@ref)     | Highlights vegetation in red, water in blue, and urban areas in grey.                    |
| [`SWIR`](@ref)              | Emphasizes dense vegetation in dark green and sparse vegetation in lighter shades.       |
| [`visualize`](@ref)         | Visualize a `Raster` or `RasterStack` containing one or more satellite bands.            |

```@autodocs
Modules = [RemoteSensingToolbox]
Pages = ["visualization.jl"]
Private = false
```

# Land Cover Indices

Land cover indices are used to highlight different types of land cover. For example, the Modified Normalized Difference Water Index (MNDWI) is used to highlight water while diminishing built-up areas. Each index is expressed as a function of two or more bands. `RemoteSensingToolbox` can automatically select the appropriate bands for a given index by providing the `Bandset` to which the image belongs. Lower-level variants are also provided for manual band selection.

| **Method**                  | **Description**                                                                          |
| :-------------------------- | :--------------------------------------------------------------------------------------- |
| [`mndwi`](@ref)             | The Modified Normalized Difference Index is used to highlight surface water features.    |
| [`nbri`](@ref)              | The Normalized Burn Ratio Index is used to emphasize burned areas.                       |
| [`ndbi`](@ref)              | The Normalized Difference Built-Up Index is used to empasize urban areas.                |
| [`ndmi`](@ref)              | The Normalized Difference Moisture Index is used to monitor droughts and dry areas.      |
| [`ndvi`](@ref)              | The Normalized Difference Vegetation Index is used to emphasize vegetation.              |
| [`ndwi`](@ref)              | The Normalized Difference Water Index is used to highlight water bodies and vegetation.  |
| [`savi`](@ref)              | The Soil Adjusted Vegetation Index is an adjusted variant of NDVI.                       |

```@autodocs
Modules = [RemoteSensingToolbox]
Pages = ["indices.jl"]
Private = false
```

# Spectral Analysis

Spectral analysis involves studying the relationships between different materials and their corresponding spectral signatures. Due to the interactions between light and matter, each signature is unique to the material that emitted it. We can exploit this fact to assign a label to each pixel, or even estimate the abundances of different materials at a sub-pixel level.

| **Method**                   | **Description**                                                                          |
| :--------------------------- | :--------------------------------------------------------------------------------------- |
| [`extract_signatures`](@ref) | Extract spectral signatures and their corresponding land cover type.                     |
| [`plot_signatures`](@ref)    | Plot the spectral signatures for each type of land cover specified in a shapefile.       |
| [`plot_signatures!`](@ref)   | The mutating version of `plot_signatures`. Writes to a `Makie.Axis` object.              |

```@autodocs
Modules = [RemoteSensingToolbox.Spectral]
Private = false
```

# Principal Component Analysis

Principal Component Analysis (PCA) is typically used to reduce the dimensionality of data. In the case of remote sensing, we are interested in reducing the number of bands we need to store while retaining as much information as possible. PCA rotates the bands into a new coordinate space where each band, called a principal component, is orthogonal to and uncorrelated with every other component. By convention, we order the bands in the transformed image in terms of their explained variance, such that the nth component accounts for more variance than any component after it.

| **Method**                    | **Description**                                                                          |
| :---------------------------- | :--------------------------------------------------------------------------------------- |
| [`fit_pca`](@ref)             | Fit a PCA transformation to the provided data and return the analytical results.         |
| [`forward_pca`](@ref)         | Run a previously learned PCA transformation on a given `Raster` or `RasterStack`.        |
| [`inverse_pca`](@ref)         | Invert a PCA transformation on a previously transformed `Raster` or `RasterStack`.       |
| [`projection`](@ref)          | Return the projection matrix for a fitted PCA transformation.                            |
| [`explained_variance`](@ref)  | Return the explained variance for each component of a fitted PCA transformation.         |
| [`cumulative_variance`](@ref) | Return the cumulative variance for each component of a fitted PCA transformation.        |


```@docs
PCA
fit_pca
forward_pca
inverse_pca
projection
explained_variance
cumulative_variance
```

# Minimum Noise Fraction

The Minimum Noise Fraction (MNF) transformation is used to separate noise from data along the spectral dimension. This method is typically used with hyperspectral imagery, both as a means of dimension reduction and for noise removal. The transformed image will have its bands placed in descending order according to their Signal to Noise Ratio (SNR). The result is that the noise becomes concentrated in the higher bands, which can then be removed by either applying a standard image denoising algorithm or dropping them altogether.

| **Method**                       | **Description**                                                                            |
| :------------------------------- | :----------------------------------------------------------------------------------------- |
| [`fit_mnf`](@ref)                | Fit an MNF transform to the provided data and return the analytical results.               |
| [`forward_mnf`](@ref)            | Run a previously learned MNF transformation on a given `Raster` or `RasterStack`.          |
| [`inverse_mnf`](@ref)            | Invert an MNF transformation on a previously transformed raster.                           |
| [`noise_cov`](@ref)              | Return the noise covariance matrix for a fitted MNF transformation.                        |
| [`data_cov`](@ref)               | Return the data covariance matrix for a fitted MNF transformation.                         |
| [`snr`](@ref)                    | Return the SNR for each principal component of a fitted  MNF transformation.               |
| [`eigenvalues`](@ref)            | Return eigenvalues for each principal component of a fitted MNF transformation.            |
| [`cumulative_snr`](@ref)         | Return the cumulative SNR for each PC of a fitted MNF transformation.                      |
| [`cumulative_eigenvalues`](@ref) | Return the cumulative eigenvalues for each PC of a fitted MNF transformation.              |

```@docs
MNF
fit_mnf
forward_mnf
inverse_mnf
noise_cov
data_cov
snr
eigenvalues
cumulative_snr
cumulative_eigenvalues
```
# Utilities

`RemoteSensingToolbox` provides several utility functions for modifying and processing remotely sensed data.

| **Method**                       | **Description**                                                                 |
| :------------------------------- | :------------------------------------------------------------------------------ |
| [`mask_pixels`](@ref)            | Remove all pixels in a raster covered by a provided mask.                       |
| [`mask_pixels!`](@ref)           | The mutating form of `mask_pixels`.                                             |
| [`tocube`](@ref)                 | Convert a multi-layer `RasterStack` into a multiband `Raster`.                  |

```@autodocs
Modules = [RemoteSensingToolbox]
Pages = ["preprocessing.jl"]
Private = false
```