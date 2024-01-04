using RemoteSensingToolbox, Rasters, ArchGDAL, Images, DataDeps, Fetch
using Pipe: @pipe

# DataDeps Settings
ENV["DATADEPS_ALWAYS_ACCEPT"] = true
ENV["DATADEPS_LOAD_PATH"] = joinpath(pwd(), "data")

# Fetch Sentinel 2 Scene from Google Drive
register(
    DataDep(
        "S2B_MSIL2A_20200804T183919_N0214_R070_T11UPT_20200804T230343", 
        """Sentinel 2 Test Data""", 
        "https://drive.google.com/file/d/1P7TSPf_GxYtyOYat3iIui1hbjvb7H6a0/view?usp=sharing", 
        "4135c6192a314e0d08d21cf44ca3cde0f34f1968854275e32656278ca163a3e0", 
        fetch_method=gdownload, 
        post_fetch_method=unpack
    )
)

# Read Sentinel 2 Bands at 60m Resolution
src = Sentinel2{60}(datadep"S2B_MSIL2A_20200804T183919_N0214_R070_T11UPT_20200804T230343")
sentinel = RasterStack(src; lazy=false)

# Extract Region of Interest
roi = @view sentinel[Rasters.X(900:1799), Rasters.Y(1:900)]

# Visualize Original Image
@pipe true_color(Sentinel2{60}, roi; upper=0.99) |> Images.save("original.jpg", _)

# Perform full PCA to determine the number of principal components to keep
pca = fit_pca(sentinel, method=:cov)
Base.show(stdout, "text/plain", pca)

# Perform a PCA Transformation, Retaining The First Three Components
transformed = forward_pca(pca, roi, 3)

# Visualize Transformation
r, g, b = (view(transformed, Rasters.Band(i)) for i in 1:3)
@pipe visualize(r, g, b; upper=0.99) |> Images.save("pca.jpg", _)

# Reverse Transformation
recovered = @pipe inverse_pca(pca, transformed) |> RasterStack(_, layersfrom=Band, name=names(roi))

# Visualize Recovered Image
@pipe true_color(Sentinel2{60}, recovered; upper=0.99) |> Images.save("recovered.jpg", _)