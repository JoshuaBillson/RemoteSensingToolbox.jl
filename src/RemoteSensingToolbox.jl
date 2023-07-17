module RemoteSensingToolbox

import ArchGDAL
import Images
import CairoMakie
import DataFrames
using Rasters
using Statistics
using DocStringExtensions
using ReadableRegex
using Pipe: @pipe

include("utils.jl")

#include("Utils/Utils.jl")

#using .Utils

include("Bandsets/Bandsets.jl")

using .Bandsets

include("indices.jl")

include("preprocessing.jl")

#include("Transformations/Transformations.jl")

#using .Transformations

#include("Spectral/Spectral.jl")

#using .Spectral

include("visualization.jl")

# Export Bandsets
export AbstractBandset, Landsat8, Landsat7, Sentinel2, DESIS
export red, green, blue, nir, swir1, swir2, bands, wavelengths, wavelength, read_bands, read_qa, dn_to_reflectance

# Export visualization
export TrueColor, ColorInfrared, SWIR, Agriculture, Geology, visualize

# Export Indices
export mndwi, ndwi, ndvi, savi, ndmi, nbri, ndbi

# Export Spectral
#export labelled_signatures, plot_signatures, plot_signatures!

# Export Preprocessing
export tocube, create_tiles, mask_pixels, mask_pixels!

# Export Transformations
export AbstractTransformation, Normalize, PCA, fit, transform

end
