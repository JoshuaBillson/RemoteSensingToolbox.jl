using RemoteSensingToolbox, Rasters, ArchGDAL, Statistics, DataFrames, Shapefile

# Read Landsat and Sentinel Bands
landsat_src = Landsat8("data/LC08_L2SP_043024_20200802_20200914_02_T1")
sentinel_src = Sentinel2{60}("data/S2B_MSIL2A_20200804T183919_N0214_R070_T11UPT_20200804T230343")
desis_src = DESIS("data/DESIS-HSI-L2A-DT0485529167_001-20220712T223540-V0220")
landsat = RasterStack(landsat_src, lazy=true)
sentinel = RasterStack(sentinel_src, lazy=true)
desis = Raster(desis_src, :Bands, lazy=true)

# Convert DNs to Surface Reflectance
landsat_sr = decode(Landsat8, landsat)
sentinel_sr = decode(Sentinel2{60}, sentinel)
desis_sr = decode(DESIS, desis)

# Load Shapefile
shp = Shapefile.Table("data/landcover/landcover.shp") |> DataFrame

# Extract Signatures
landsat_sigs = extract_signatures(mean, landsat_sr, shp, :MC_name) |> DataFrame

# Plot Signatures
import CairoMakie
fig = plot_signatures(Landsat8, landsat_sigs)
CairoMakie.save("landsat_sigs_wong.png", fig)

# Plot Signatures With Custom Colors
colors = [:saddlebrown, :orange, :navy, :green]
fig = plot_signatures(Landsat8, landsat_sigs, colors=colors)
CairoMakie.save("landsat_sigs_custom.png", fig)

# Create Figure
fig = CairoMakie.Figure(resolution=(1000, 800))

# Create Axes
ax1 = CairoMakie.Axis(fig[1,1], title="Landsat 8", xticksvisible=false, xticklabelsvisible=false)
ax2 = CairoMakie.Axis(fig[2,1], title="Sentinel 2", ylabel="Reflectance", ylabelfont=:bold, xticksvisible=false, xticklabelsvisible=false)
ax3 = CairoMakie.Axis(fig[3,1], title="DESIS", xlabel="Wavelength (nm)", xlabelfont=:bold)

# Plot Signatures
axs = (ax1, ax2, ax3)
sensors = (Landsat8, Sentinel2{60}, DESIS)
rasters = (landsat_sr, sentinel_sr, desis_sr)
for (sensor, raster, ax) in zip(sensors, rasters, axs)
    sigs = extract_signatures(mean, raster, shp, :MC_name)
    plot_signatures!(ax, sensor, sigs; colors=colors)
    CairoMakie.xlims!(ax, 400, 1000)
end

# Add Legend
CairoMakie.Legend(fig[1:3,2], first(axs), "Classification")

# Save Figure
CairoMakie.save("multisensor_sigs.png", fig)