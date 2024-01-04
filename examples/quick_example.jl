using RemoteSensingToolbox, Rasters, ArchGDAL, Images, DataDeps, Fetch
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

# Show True Color Composite
@pipe true_color(src; upper=0.90) |> Images.imresize(_, ratio=0.25) |> Images.save("true_color.jpg", _)

# Show Agriculture Composite
@pipe agriculture(src; upper=0.90) |> Images.imresize(_, ratio=0.25) |> Images.save("agriculture.jpg", _)

# Mask Clouds
stack = RasterStack(src; lazy=true)
cloud_mask = Raster(src, :clouds)
shadow_mask = Raster(src, :cloud_shadow)
masked = apply_masks(stack, cloud_mask, shadow_mask)

# Visualize Cloudless Raster
@pipe true_color(Landsat8, masked) |> Images.imresize(_, ratio=0.25) |> Images.save("masked.jpg", _)

# Display Landcover Indexes
roi = @view masked[X(5800:6800), Y(2200:3200)]
tc = true_color(Landsat8, roi; upper=0.998)
indices = map(visualize, [mndwi(Landsat8, roi), ndvi(Landsat8, roi), ndmi(Landsat8, roi)])
mosaic = mosaicview([tc, indices...]; npad=10, fillvalue=0.0, ncol=2, rowmajor=true)
Images.save("indices.jpg", mosaic)