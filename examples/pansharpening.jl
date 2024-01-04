using RemoteSensingToolbox, Rasters, ArchGDAL, Images, DataDeps, Fetch

# DataDeps Settings
ENV["DATADEPS_ALWAYS_ACCEPT"] = true
ENV["DATADEPS_LOAD_PATH"] = joinpath(pwd(), "data")

# Fetch Landsat 8 Scene from Google Drive
register(
    DataDep(
        "LC08_L1TP_043024_20200802_20200914_02_T1", 
        """Landast 8 Pansharpening Example""", 
        "https://drive.google.com/file/d/107GjXFqmtKeNMLdOUreq3jl5wWGCpYro/view?usp=sharing", 
        "d6dc0c29e76db6f60ac665194ddd565cb808417250218f35f2f405a97064f297", 
        fetch_method=gdownload, 
        post_fetch_method=unpack
    )
)

# Read RGB and Panchromatic Bands
src = Landsat8(datadep"LC08_L1TP_043024_20200802_20200914_02_T1")
stack = RasterStack(src, [:red, :green, :blue], lazy=true)
panchromatic = Raster(src, :panchromatic, lazy=true)

# Crop to Region of Interest
roi = @view stack[X(6715:6914), Y(1500:1699)]
roi_hr = Rasters.resample(roi, res=15)  # Resample RGB to 15m
roi_pan = Rasters.crop(panchromatic, to=roi_hr)

# Visualize RGB and Panchromatic Bands
rgb = visualize(roi_hr...)
pan = visualize(roi_pan)
img = mosaicview(rgb, pan, npad=1, ncol=2, rowmajor=false, fillvalue=RGB(1.0,1.0,1.0))
Images.save("comparison.jpg", img)

# Convert to HSV and Replace Value Band with Panchromatic
hsv = HSV.(rgb)
adjust_histogram!(pan, Matching(targetimg=channelview(hsv)[3,:,:]))
channelview(hsv)[3,:,:] .= gray.(pan)
sharpened = RGB.(hsv)

# Visualize
img = mosaicview(rgb, sharpened, npad=1, ncol=2, rowmajor=false, fillvalue=RGB(1.0,1.0,1.0))
Images.save("pansharpened.jpg", img)