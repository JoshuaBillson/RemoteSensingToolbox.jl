using RemoteSensingToolbox, Test, SafeTestsets
using Pipe: @pipe

@safetestset "Indices" begin include("indices.jl") end

@safetestset "PCA" begin include("pca.jl") end

@safetestset "Makie" begin include("makie.jl") end

@safetestset "Utilities" begin include("utils.jl") end

@safetestset "Visualization" begin include("visualization.jl") end