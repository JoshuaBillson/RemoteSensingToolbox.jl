using Test, Statistics
using RemoteSensingToolbox, Rasters, DataFrames
using Pipe: @pipe

# Read Landsat Bands
src = Landsat8("data/LC08_L2SP_043024_20200802_20200914_02_T1")
stack = RasterStack(src, lazy=true)

# Test has_bands and nbands
r1 = Raster(rand(Float32, 128, 128, 1), (X, Y, Band))
r2 = Raster(rand(Float32, 128, 128, 235), (X, Y, Band))
r3 = Raster(rand(Float32, 128, 128), (X, Y))
@test has_bands(r1)
@test has_bands(r2)
@test !has_bands(r3)
@test nbands(r1) == 1
@test nbands(r2) == 235
@test nbands(r3) == 1
@test nbands(RasterStack(r1, layersfrom=Band)) == 1
@test nbands(RasterStack(r2, layersfrom=Band)) == 235
@test nbands(RasterStack(r3)) == 1

# Test mask_nan!
r = Raster([0.0f0 NaN32; 1.0f0 1.0f0], (X, Y), missingval=0.0f0)
mask_nan!(r)
@test r.data == [0.0f0 0.0f0; 1.0f0 1.0f0]

# Test table
df1 = table(stack, DataFrame)
df2 = dropmissing(df1)
@test nrow(df1) == reduce(*, size(stack))
@test nrow(df2) == (reduce((a, b) -> boolmask(a) .* boolmask(b), (stack...,)) |> skipmissing |> collect |> length)
@test all(Tables.columnnames(df1) .== [:geometry, :B1, :B2, :B3, :B4, :B5, :B6, :B7])
@test all(Tables.columnnames(df2) .== [:geometry, :B1, :B2, :B3, :B4, :B5, :B6, :B7])

# Test sample
r1 = Raster(rand(Float32, 128, 128, 235), (X, Y, Band))
r2 = Raster(rand(Float32, 128, 128), (X, Y))
s1 = sample(r1, DataFrame, fraction=0.1)
s2 = sample(r2, DataFrame, fraction=0.1)
s3 = sample(r1, DataFrame, fraction=1.0)
@test nrow(s1) == round(Int, reduce(*, size(r1)[1:2]) * 0.1)
@test nrow(s2) == round(Int, reduce(*, size(r2)[1:2]) * 0.1)
@test nrow(s3) == reduce(*, size(r1)[1:2])
@test !(:geometry in Tables.columnnames(s1))
@test length(Tables.columnnames(s1)) == 235
@test length(Tables.columnnames(s2)) == 1

# Test apply_masks
r = Raster([0.0f0 1.0f0 1.0f0; 1.0f0 1.0f0 1.0f0; 1.0f0 1.0f0 1.0f0], (X, Y), missingval=0.0f0)
m1 = Raster([0.0f0 0.0f0 1.0f0; 0.0f0 0.0f0 0.0f0; 0.0f0 0.0f0 1.0f0], (X, Y), missingval=0.0f0)
m2 = Raster([0.0f0 0.0f0 1.0f0; 1.0f0 0.0f0 0.0f0; 0.0f0 0.0f0 0.0f0], (X, Y), missingval=0.0f0)
masked1 = Raster([0.0f0 1.0f0 0.0f0; 0.0f0 1.0f0 1.0f0; 1.0f0 1.0f0 0.0f0], (X, Y), missingval=0.0f0)
masked2 = Raster([0.0f0 1.0f0 0.0f0; 1.0f0 1.0f0 1.0f0; 1.0f0 1.0f0 0.0f0], (X, Y), missingval=0.0f0)
@test all(apply_masks(r, m1, m2) .== masked1)
@test r.data != masked1.data
@test all(apply_masks(r, m1) .== masked2)
@test all(apply_masks!(r, m1, m2) .== masked1)
@test all(r .== masked1)

# Test nonmissing
r1 = Raster([0.0f0 1.0f0 1.0f0; 0.0f0 1.0f0 0.0f0; 1.0f0 0.0f0 1.0f0], (X, Y), missingval=0.0f0)
r2 = Raster([1.0f0 1.0f0 0.0f0; 1.0f0 1.0f0 1.0f0; 0.0f0 1.0f0 1.0f0], (X, Y), missingval=0.0f0)
rs = RasterStack((a=r1, b=r2))
@test all(RemoteSensingToolbox.nonmissing(r1) .== [3, 4, 5, 7, 9])
@test all(RemoteSensingToolbox.nonmissing(rs) .== [4, 5, 9])
