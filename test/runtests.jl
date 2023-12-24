using RemoteSensingToolbox, Test, SafeTestsets
using Pipe: @pipe

#@safetestset "Landsat" begin include("landsat.jl") end

#@safetestset "Sentinel" begin include("sentinel.jl") end

#@safetestset "PCA" begin include("pca.jl") end

@safetestset "Makie" begin include("makie.jl") end

#@safetestset "Preprocessing" begin include("preprocessing.jl") end