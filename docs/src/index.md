```@meta
CurrentModule = RSToolbox
```

# RSToolbox

Documentation for [RSToolbox](https://github.com/JoshuaBillson/RSToolbox.jl).

# Index

```@index
```

# Sensors
Sensors are julia structs that wrap a typical `Rasters.RasterStack` object to provide compatability with many `RSToolbox` algorithms and methods.

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

```@docs
RSToolbox.AbstractSensor
Landsat8
Landsat7
Sentinel2A
red
green
blue
nir
swir1
swir2
dn_to_reflectance
asraster
```

# Visualization

```@docs
visualize
TrueColor
ColorInfrared
SWIR
Agriculture
Geology
```

# Land Cover Indices

```@docs
mndwi
ndwi
ndvi
savi
ndmi
nbri
ndbi
```