module RemoteSensingToolbox

import ImageCore
import Tables
import TableOperations
import LinearAlgebra
import Random
import ArchGDAL

using Rasters
using Statistics
using DocStringExtensions
using DataFrames
using Bijections

using Pipe: @pipe
using Reexport: @reexport

@reexport using SatelliteDataSources

const RasterOrStack = Union{<:AbstractRasterStack, <:AbstractRaster}

include("utils.jl")

include("preprocessing.jl")

include("visualization.jl")

include("indices.jl")

include("pca.jl")

include("spectral_analysis.jl")

# Export visualization
export TrueColor, ColorInfrared, SWIR, Agriculture, Geology, visualize

# Export Indices
export mndwi, ndwi, ndvi, savi, ndmi, nbri, ndbi

# Export Spectral
export extract_signatures, plot_signatures, plot_signatures!

# Export Preprocessing
#export tocube, create_tiles, mask_pixels, mask_pixels!, encode

# Export Transformations
export PCA, MNF, fit_pca, forward_pca, inverse_pca, fit_mnf, forward_mnf, inverse_mnf
export noise_cov, data_cov, projection, eigenvalues, cumulative_eigenvalues, snr, cumulative_snr, cumulative_variance, explained_variance

end
