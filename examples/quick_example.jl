using RemoteSensingToolbox, Images, CairoMakie, Rasters
using Pipe: @pipe

function main()
    # Read Landsat Bands
    landsat = read_bands(Landsat8, "data/LC08_L2SP_043024_20200802_20200914_02_T1/")

    # Convert DN to Reflectance
    landsat_sr = dn_to_reflectance(Landsat8, landsat)

    # Show True Color Composite
    @pipe visualize(landsat_sr, TrueColor{Landsat8}; upper=0.90) |> Images.imresize(_, ratio=0.2) |> Images.save("true_color.png", _)

    # Mask Clouds
    qa = read_qa(Landsat8, "data/LC08_L2SP_043024_20200802_20200914_02_T1/")
    masked_landsat = @pipe mask_pixels(landsat_sr, qa[:cloud]) |> mask_pixels(_, qa[:cloud_shadow])

    # Visualize Cloudless Raster
    @pipe visualize(masked_landsat, TrueColor{Landsat8}) |> Images.imresize(_, ratio=0.2) |> Images.save("cloudless.png", _)

    # Show Color Infrared Composite
    @pipe visualize(landsat_sr, ColorInfrared{Landsat8}; upper=0.90) |> Images.imresize(_, ratio=0.2) |> Images.save("color_infrared.png", _)

    # Show Agriculture Composite
    @pipe visualize(landsat_sr, Agriculture{Landsat8}; upper=0.90) |> Images.imresize(_, ratio=0.2) |> Images.save("agriculture.png", _)

    # Select Region of Interest
    roi = @view landsat_sr[X(5800:6800), Y(2200:3200)]

    # Show MNDWI
    true_color = visualize(roi, TrueColor{Landsat8}; upper=0.998)
    index = mndwi(roi, Landsat8) |> visualize
    @pipe mosaicview(true_color, index; npad=5, fillvalue=0.0, ncol=2) |> Images.save("mndwi.png", _)
end

main()