using RemoteSensingToolbox, JpegTurbo, Images, Rasters
using Pipe: @pipe

function main()
    # Read Landsat Bands
    src = Landsat8("data/LC08_L2SP_043024_20200802_20200914_02_T1/")
    stack = RasterStack(src, lazy=true)

    # Show True Color Composite
    @pipe visualize(TrueColor{Landsat8}, stack; upper=0.90) |> Images.imresize(_, ratio=0.25) |> Images.save("true_color.jpg", _)

    # Show Color Infrared Composite
    @pipe visualize(ColorInfrared{Landsat8}, stack; upper=0.90) |> Images.imresize(_, ratio=0.25) |> Images.save("color_infrared.jpg", _)

    # Show Agriculture Composite
    @pipe visualize(Agriculture{Landsat8}, stack; upper=0.90) |> Images.imresize(_, ratio=0.25) |> Images.save("agriculture.jpg", _)

    # Mask Clouds
    cloud_mask = Raster(src, :clouds)
    shadow_mask = Raster(src, :cloud_shadow)
    raster_mask = .!(boolmask(cloud_mask) .|| boolmask(shadow_mask))
    masked = mask(stack, with=raster_mask)

    # Visualize Cloudless Raster
    @pipe visualize(TrueColor{Landsat8}, masked) |> Images.imresize(_, ratio=0.25) |> Images.save("masked.jpg", _)

    # Display Landcover Indexes
    indices = RasterStack((mndwi=mndwi(src), ndvi=ndvi(src), ndmi=ndmi(src)))
    roi = @view merge(stack, indices)[X(5800:6800), Y(2200:3200)]
    true_color = visualize(TrueColor{Landsat8}, roi; upper=0.998)
    index_imgs = [visualize(roi[i]) for i in (:mndwi, :ndvi, :ndmi)]
    @pipe mosaicview(true_color, index_imgs...; npad=10, fillvalue=0.0, ncol=2, rowmajor=true) |> Images.save("indices.jpg", _)
end

main()