```@meta
CurrentModule = RemoteSensingToolbox
```

# RemoteSensingToolbox

[RemoteSensingToolbox](https://github.com/JoshuaBillson/RemoteSensingToolbox.jl) is a pure Julia package intended to provide a collection of tools for visualizing, manipulating, and interpreting remotely sensed imagery.

`RemoteSensingToolbox` provides a number of utilities for . First, lets load the imagery we want to work with. We're using Landsat 8 imagery in this example, so we'll pass the `Landsat8` type to `read_bands` so it knows how to parse the relevant files from the provided directory. `Landsat8` is an instance of `AbstractBandset`, which is the supertype responsible for allowing many methods within `RemoteSensingToolbox` to infer sensor-specific information by exploiting Julia's multiple dispatch system.
# Bandsets

Bandsets are julia types that encode the sensor-specific information needed for many methods in `RemoteSensingToolbox` to work without the need for tedious details provided by the end user. 

|                           |                                                                              |
| :------------------------ | :--------------------------------------------------------------------------- |
| `Base.getindex`           | return the layer correspinding to the given band name.                       |
| `Base.length`             | return the number of layers in the enclosed `Rasters.RasterStack`.           |
| `Base.map`                | apply a function to each layer in the enclosed `Rasters.RasterStack`.        |
| `Base.write`              | write layers to file.                                                        |
| `Rasters.resample`        | resample data to a different size and projection, or snap to another object. |
| `Rasters.crop`            | shrink objects to specific dimension sizes or the extent of another object.  |
| `Rasters.extend`          | extend objects to specific dimension sizes or the extent of another object.  |
| `Rasters.trim`            | trims areas of missing values for arrays and across stack layers.            |
| `Rasters.mask`            | mask an object by a polygon or Raster along X/Y, or other dimensions.        |
| `Rasters.replace_missing` | replace all missing values in an object and update missingval.               |

Additionally, [`asraster`](@ref) can be used to apply a function to the enclosed `Rasters.RasterStack`.

```@autodocs
Modules = [RemoteSensingToolbox.Sensors]
```

# Visualization

```@autodocs
Modules = [RemoteSensingToolbox]
Pages = ["visualization.jl"]
```

# Preprocessing

```@autodocs
Modules = [RemoteSensingToolbox]
Pages = ["preprocessing.jl"]
```

# Land Cover Indices

```@autodocs
Modules = [RemoteSensingToolbox]
Pages = ["indices.jl"]
```

# Spectral Analysis

```@autodocs
Modules = [RemoteSensingToolbox.Spectral]
```

# Transformations

```@autodocs
Modules = [RemoteSensingToolbox.Transformations]
```