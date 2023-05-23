using RemoteSensingToolbox, Images, CairoMakie, Rasters
using Pipe: @pipe

function main()
    # Read Landsat Bands
    landsat = Landsat8("data/LC08_L2SP_043024_20200802_20200914_02_T1/")

    # Show A Mosaic Of All Bands
    @pipe mosaicview(landsat; upper=0.90, rowmajor=true, ncol=4) |> Images.save("mosaic.png", _)

    # Show True Color Composite
    @pipe visualize(landsat, TrueColor; upper=0.90) |> Images.imresize(_, ratio=0.2) |> Images.save("true_color.png", _)

    # Show Color Infrared Composite
    @pipe visualize(landsat, ColorInfrared; upper=0.90) |> Images.imresize(_, ratio=0.2) |> Images.save("color_infrared.png", _)

    # Show Agriculture Composite
    @pipe visualize(landsat, Agriculture; upper=0.90) |> Images.imresize(_, ratio=0.2) |> Images.save("agriculture.png", _)

    # Show MNDWI
    patch = @view landsat[X(5800:6800), Y(2200:3200)]
    true_color = visualize(patch, TrueColor; upper=0.998)
    index = mndwi(patch) |> visualize
    @pipe mosaicview(true_color, index; npad=5, fillvalue=0.0, ncol=2) |> Images.save("patches.png", _)
end

main()