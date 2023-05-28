```@meta
CurrentModule = RemoteSensingToolbox
```

# Preprocessing Example

In remote sensing, we often want to preprocess our imagery before using it in further analysis. For example, we may want to convert digital numbers to surface reflectance, crop to a region of interest, or cut our image into manageable tiles before feeding it into a machine learning algorithm. The first step is to read our data from disk. A variety of commons sensors are supported by `RemoteSensingToolbox`, but today we're going to be working with Landsat 8 imagery.

```julia
using RemoteSensingToolbox, Rasters, Images
using Pipe: @pipe

landsat = Landsat8("LC08_L2SP_043024_20200802_20200914_02_T1/")
```

Most remote sensing images encode each pixel as a Digital Number (DN). Unfortunately, this is not very interpretable for a variety of applications, particularly in the case of land cover classification. A much better measurement is reflectance, which is defined as a number between 0 and 1, which indicates the fraction of light that is reflected by the observed surface. The specifics of converting from DN to reflectance differs from one sensor to the next. Fortunately, all `AbstractSensor` types contain this information implicitly. Thus, we can simple call `dn_to_reflectance` to turn our DNs to surface reflectance.

```julia
landsat_sr = dn_to_reflectance(landsat)
```

When we visualize our data, we observe the present of a large number of clouds.

```julia
visualize(landsat_sr, TrueColor; upper=0.90)
```

![](figures/true_color.png)

In many applications, we need to remove all pixels covered by clouds before further processing. Fortunately, Landsat images comes with a Quality Assurance (QA) file which, among other things, gives us a mask of all detected cloud pixels. However, this data is not easy to interpret, as each mask is encided as a specific bit in an unsigned 16 bit integer. `RemoteSensingToolbox` provides the `landsat_qa` method to decode the QA image into a more interpretable form.

```julia
qa = landsat_qa("LC08_L2SP_043024_20200802_20200914_02_T1/LC08_L2SP_043024_20200802_20200914_02_T1_QA_PIXEL.TIF")
```

```
RasterStack with dimensions: 
  X Projected{Float64} LinRange{Float64}(493785.0, 728385.0, 7821) ForwardOrdered Regular Points crs: WellKnownText,
  Y Projected{Float64} LinRange{Float64}(5.84638e6, 5.60878e6, 7921) ReverseOrdered Regular Points crs: WellKnownText
and 8 layers:
  :fill          UInt8 dims: X, Y (7821×7921)
  :dilated_cloud UInt8 dims: X, Y (7821×7921)
  :cirrus        UInt8 dims: X, Y (7821×7921)
  :cloud         UInt8 dims: X, Y (7821×7921)
  :cloud_shadow  UInt8 dims: X, Y (7821×7921)
  :snow          UInt8 dims: X, Y (7821×7921)
  :clear         UInt8 dims: X, Y (7821×7921)
  :water         UInt8 dims: X, Y (7821×7921)
```

Now that we have the QA masks, we can use the `mask_pixels` method to remove the presence of clouds and cloud shadows.

```julia
@pipe mask_pixels(landsat_sr, qa[:cloud]) |> 
mask_pixels(_, qa[:cloud_shadow]) |> 
visualize(_, TrueColor)
```

![](figures/masked.png)

Next, let's crop our rasters to a region of interest. All `AbstractSensor` types are compatible with the standard view and index operations supported by `Rasters.jl`.

```julia
roi = @view landsat_sr[X(5801:6800), Y(2201:3200)]
```

Remotely sensed imagery is often too large to be used directly in machine learning applications. Thus, it is common practice to cut a raster into several smaller tiles, which may partially overlap with one another to increase the number of samples available to us. This can be accomplished with the `create_tiles` method, which provides an optional `stride` argument specifying how far apart each tile should be in the x and y dimensions. By default, `stride` is equal to the tile size, but setting `stride` to a smaller value allows us to generate overlapping tiles.

```julia
tiles = create_tiles(roi, (500, 500))
overlapping_tiles = create_tiles(roi, (500, 500); stride=(250, 250))
```

To better understand how `create_tiles` works, let's visualize the result of generating non-overlapping and half-overlapping tiles.

```julia
@pipe tiles |> 
visualize.(_, TrueColor; upper=0.998) |> 
mosaicview(_, ncol=2, rowmajor=true, npad=5, fillvalue=1.0)
```

![](figures/landsat_tiles.png)

```julia
@pipe overlapping_tiles |> 
visualize.(_, TrueColor; upper=0.998) |> 
mosaicview(_, ncol=2, rowmajor=true, npad=5, fillvalue=1.0)
```

![](figures/landsat_overlapping_tiles.png)

Finally, we're ready to save our tiles to disk. However, instead of saving each band as a separate file, we can combine them into a single multi-band raster. To do so, we use the `tocube` method, which optionally takes a list of layers that we want to write to the raster. By default, all layers are included. In this example, we will keep only the blue, green, red, and nir bands for each tile.

```julia
cubes = map(x -> tocube(x; layers=[:B2, :B3, :B4, :B5]), tiles)
for (i, cube) in enumerate(cubes)
   Rasters.write("tile_$i.tif", cube)
end
```