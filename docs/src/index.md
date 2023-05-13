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