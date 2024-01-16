using Test, Statistics
using RemoteSensingToolbox, Rasters, DataFrames
using Pipe: @pipe

# Read Landsat Bands
src = Landsat8("data/LC08_L2SP_043024_20200802_20200914_02_T1")
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
