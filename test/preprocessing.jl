using RemoteSensingToolbox, Test, ArchGDAL, Rasters
using Pipe: @pipe

# Load Sentinel
sentinel = read_bands(Sentinel2, "data/sentinel/")

# Test Tiles
t1 = create_tiles(sentinel, (610, 610))
t2 = create_tiles(sentinel, (611, 611))
t3 = create_tiles(sentinel, (610, 610), stride=(305, 305))
@test length(t1) == 9
@test length(t2) == 4
@test length(t3) == 25
@test all(map(x -> size(x) == (610, 610), t1))
@test all(map(x -> size(x) == (611, 611), t2))
@test all(map(x -> size(x) == (610, 610), t3))

# Test Mask
qa = read_qa(Sentinel2, "data/sentinel")
b1 = qa[:water] |> boolmask
b2 = mask_pixels(sentinel, qa[:water], invert_mask=true) |> boolmask
b3 = mask_pixels!(copy(sentinel), qa[:water], invert_mask=true) |> boolmask
b4 = mask_pixels(sentinel, qa[:water]) |> boolmask
b5 = mask_pixels!(copy(sentinel), qa[:water]) |> boolmask
@test all(b1 .== b2)
@test all(b1 .== b3)
@test all(b1 .!= b4)
@test all(b1 .!= b5)

# Test Encode
m = Rasters.missingval(sentinel) |> first
sentinel_float = encode(sentinel, Float32)
sentinel_int = encode(sentinel_float, UInt16, missingval=m)
@test all(collect(missingval(sentinel_float)) .== Inf32)
@test all(collect(missingval(sentinel_int)) .== collect(Rasters.missingval(sentinel)))
@test all(tocube(sentinel_float) .== tocube(sentinel_int))