```@meta
CurrentModule = RemoteSensingToolbox
```

# RemoteSensingToolbox

[RemoteSensingToolbox](https://github.com/JoshuaBillson/RemoteSensingToolbox.jl) is a pure Julia package intended to provide a collection of commonly used tools for working with remotely sensed imagery.

# Sensors

Sensors are julia structs that wrap a typical `Rasters.RasterStack` object to provide compatability with many `RemoteSensingToolbox` algorithms and methods.

The following methods are supported by all `AbstractSensor` types:

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
Modules = [RemoteSensingToolbox.Preprocessing]
```

# Land Cover Indices

```@autodocs
Modules = [RemoteSensingToolbox.Algorithms]
Pages = ["Algorithms/indices.jl"]
```

# Spectral Analysis

```@autodocs
Modules = [RemoteSensingToolbox.Spectral]
```