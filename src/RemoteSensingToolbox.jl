module RemoteSensingToolbox

import Images
import CairoMakie
using Rasters
using Statistics
using DocStringExtensions
using Pipe: @pipe

include("utils.jl")

#include("Utils/Utils.jl")

#using .Utils

include("Bandsets/Bandsets.jl")

using .Bandsets

#include("indices.jl")

#include("preprocessing.jl")

#include("Transformations/Transformations.jl")

#using .Transformations

#include("Spectral/Spectral.jl")

#using .Spectral

include("visualization.jl")

# Export Bandsets
export AbstractBandset,Landsat8, Landsat7, Sentinel2, DESIS
export red, green, blue, nir, swir1, swir2, unwrap, wavelength, wavelengths, bands

# Export visualization
export TrueColor, ColorInfrared, SWIR, Agriculture, Geology, visualize

# Export Indices
#export mndwi, ndwi, ndvi, savi, ndmi, nbri, ndbi

# Export Spectral
#export labelled_signatures, plot_signatures, plot_signatures!

# Export Preprocessing
#export tocube, dn_to_reflectance, create_tiles, mask_pixels, landsat_qa

# Export Transformations
export AbstractTransformation, Normalize, PCA, fit, transform

end
