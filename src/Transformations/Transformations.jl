module Transformations

using Rasters
using DocStringExtensions
using Statistics
using Pipe: @pipe

import Tables
import Random
import LinearAlgebra
import RemoteSensingToolbox

include("utils.jl")
include("pca.jl")
include("mnf.jl")
#include("normalize.jl")

export PCA, MNF, fit_pca, forward_pca, inverse_pca, fit_mnf, forward_mnf, inverse_mnf
export noise_cov, data_cov, projection, eigenvalues, cumulative_eigenvalues, snr, cumulative_snr, cumulative_variance, explained_variance

end