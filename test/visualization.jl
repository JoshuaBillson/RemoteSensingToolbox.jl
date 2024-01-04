using Test, Statistics
using RemoteSensingToolbox, Rasters, ArchGDAL, DataFrames
using DataDeps, Fetch
using Pipe: @pipe

# DataDeps Settings
ENV["DATADEPS_ALWAYS_ACCEPT"] = true
ENV["DATADEPS_LOAD_PATH"] = joinpath(pwd(), "data")

# Fetch Landsat Scene from Google Drive
register(
    DataDep(
        "LC08_L2SP_043024_20200802_20200914_02_T1", 
        "Landsat 8 Test Data",
        "https://drive.google.com/file/d/1S5H_oyWZZInOzJK4glBCr6LgXSADzhOV/view?usp=sharing", 
        "2ce24abc359d30320213237d78101d193cdb8433ce21d1f7e9f08ca140cf5785", 
        fetch_method=gdownload, 
        post_fetch_method=unpack
    )
)

# Read Landsat Bands
src = Landsat8(datadep"LC08_L2SP_043024_20200802_20200914_02_T1")
stack = RasterStack(src, lazy=false)

# Band Combinations
@test all(true_color(src) .== true_color(Landsat8, stack))
@test all(color_infrared(src) .== color_infrared(Landsat8, stack))
@test all(swir(src) .== swir(Landsat8, stack))
@test all(agriculture(src) .== agriculture(Landsat8, stack))
@test all(geology(src) .== geology(Landsat8, stack))

# Manual Band Entry
@test all(visualize(stack[:B4], stack[:B3], stack[:B2]) .== true_color(Landsat8, stack))
@test all(visualize(stack[:B5], stack[:B4], stack[:B3]) .== color_infrared(Landsat8, stack))
@test all(visualize(stack[:B7], stack[:B6], stack[:B4]) .== swir(Landsat8, stack))
@test all(visualize(stack[:B6], stack[:B5], stack[:B2]) .== agriculture(Landsat8, stack))
@test all(visualize(stack[:B7], stack[:B6], stack[:B2]) .== geology(Landsat8, stack))
