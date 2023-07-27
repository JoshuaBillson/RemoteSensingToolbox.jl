using RemoteSensingToolbox, Rasters, Images
using Pipe: @pipe

function main()
    # Read Landsat
    sentinel = read_bands(Sentinel2, "data/T11UPT_20200804T183919/R60m/")
    roi = @view sentinel[Rasters.X(900:1799), Rasters.Y(1:900)]

    # Visualize Original Image
    @pipe visualize(roi, TrueColor{Sentinel2}; upper=0.99) |> Images.save("original.png", _)

    # Perform full PCA to determine the number of principal components to keep
    pca_full = fit_transform(PCA, sentinel, method=:cov)
    Base.show(stdout, "text/plain", pca_full)

    # Fit a PCA transform that retains the first three principal components
    pca = fit_transform(PCA, sentinel, components=3)

    # Perform Transformation
    transformed = transform(pca, roi)

    # Visualize Transformation
    r, g, b = [view(transformed, Rasters.Band(i)) for i in 1:3]
    @pipe visualize(r, g, b; upper=0.99) |> Images.save("pca.png", _)

    # Reverse Transformation
    recovered = inverse_transform(pca, transformed)

    # Visualize Recovered Image
    @pipe visualize(recovered, TrueColor{Sentinel2}; upper=0.99) |> Images.save("recovered.png", _)
end