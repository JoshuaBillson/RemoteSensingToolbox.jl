using RemoteSensingToolbox, Test, SafeTestsets, Tar
using Pipe: @pipe

# Extract Test Data From Tar Files
Tar.extract(
    "data/S2B_MSIL2A_20200804T183919_N0214_R070_T11UPT_20200804T230343.tar", 
    "data/S2B_MSIL2A_20200804T183919_N0214_R070_T11UPT_20200804T230343")

Tar.extract(
    "data/LC08_L2SP_043024_20200802_20200914_02_T1.tar", 
    "data/LC08_L2SP_043024_20200802_20200914_02_T1")

@safetestset "Indices" begin include("indices.jl") end

@safetestset "PCA" begin include("pca.jl") end

@safetestset "Makie" begin include("makie.jl") end

@safetestset "Utilities" begin include("utils.jl") end

@safetestset "Visualization" begin include("visualization.jl") end

# Remove Extracted Files
rm("data/S2B_MSIL2A_20200804T183919_N0214_R070_T11UPT_20200804T230343", recursive=true)
rm("data/LC08_L2SP_043024_20200802_20200914_02_T1", recursive=true)
