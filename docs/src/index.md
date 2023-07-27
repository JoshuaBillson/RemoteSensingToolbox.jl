```@meta
CurrentModule = RemoteSensingToolbox
```

# RemoteSensingToolbox

[RemoteSensingToolbox](https://github.com/JoshuaBillson/RemoteSensingToolbox.jl) is a pure Julia package intended to provide a collection of tools for visualizing, manipulating, and interpreting remotely sensed imagery.

# Bandsets

Bandsets are julia types that encode the sensor-specific information needed for many methods in `RemoteSensingToolbox` to work without the need for tedious details provided by the end user. Bandsets are provided for several common sensors including Sentinel-2, Landsat 7, and Landsat 8. Unsupported sensors can be added by defining a custom type, which should be a sub-type of `AbstractBandset`, and implementing the following interface:

| **Method**                  | **Description**                                                                          | **Required**    |
| :-------------------------- | :--------------------------------------------------------------------------------------- | :-------------: |
| [`bands`](@ref)             | Return the band names in order from shortest to longest wavelength.                      | yes             |
| [`wavelengths`](@ref)       | Return the central wavelengths for all bands from shortest to longest.                   | yes             |
| [`blue`](@ref)              | Return the blue band for the given sensor.                                               | yes             |
| [`green`](@ref)             | Return the green band for the given sensor.                                              | yes             |
| [`red`](@ref)               | Return the red band for the given sensor.                                                | yes             |
| [`nir`](@ref)               | Return the nir band for the given sensor.                                                | yes             |
| [`swir1`](@ref)             | Return the swir1 band for the given sensor.                                              | yes             |
| [`swir2`](@ref)             | Return the swir2 band for the given sensor.                                              | yes             |
| [`parse_band`](@ref)        | Parses the band from a given filename. Used by [`read_bands`](@ref).                     | no              |
| [`read_qa`](@ref)           | Reads the QA or scene classification file from the provided file or directory.           | no              |
| [`dn_to_reflectance`](@ref) | Decodes digital numbers to reflectance.                                                  | no              |


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
Private = false
```

# Transformations

```@autodocs
Modules = [RemoteSensingToolbox.Transformations]
Private = false
```