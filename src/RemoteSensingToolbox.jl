module RemoteSensingToolbox

import ArchGDAL
import ImageCore
import Tables
import TableOperations
using OrderedCollections
using Rasters
using Statistics
using DocStringExtensions
using ReadableRegex
using Pipe: @pipe

include("utils.jl")

include("raster_table.jl")

include("Bandsets/Bandsets.jl")

using .Bandsets

include("indices.jl")

include("preprocessing.jl")

include("Transformations/Transformations.jl")

using .Transformations

include("Spectral/Spectral.jl")

using .Spectral

include("visualization.jl")

# Export RasterTable
export RasterTable, dropmissing!, dropmissing, layers, cols, nonmissing, transform_column!, fold_rows

# Export Bandsets
export AbstractBandset, Landsat8, Landsat7, Sentinel2, DESIS
export red, green, blue, nir, swir1, swir2, bands, wavelengths, wavelength, read_bands, read_qa, dn_to_reflectance, parse_band

# Export visualization
export TrueColor, ColorInfrared, SWIR, Agriculture, Geology, visualize

# Export Indices
export mndwi, ndwi, ndvi, savi, ndmi, nbri, ndbi

# Export Spectral
export extract_signatures, summarize_signatures, plot_signatures, plot_signatures!

# Export Preprocessing
export tocube, create_tiles, mask_pixels, mask_pixels!

# Export Transformations
export PCA, MNF, fit_pca, forward_pca, inverse_pca, fit_mnf, forward_mnf, inverse_mnf
export noise_cov, data_cov, projection, eigenvalues, cumulative_eigenvalues, snr, cumulative_snr, cumulative_variance, explained_variance

end
