using Test, Statistics
using RemoteSensingToolbox, Rasters
using DataFrames, GeoDataFrames
using Pipe: @pipe

# Load Sentinel
src = Sentinel2{60}("data/S2B_MSIL2A_20200804T183919_N0214_R070_T11UPT_20200804T230343")
sentinel = @pipe RasterStack(src) |> decode(Sentinel2{60}, _)

# Read Shapefile
shp = GeoDataFrames.read("data/landcover/landcover.shp")

# Extract Signatures
sigs = extract_signatures(mean, sentinel, shp, :MC_name)

# Should Throw Error Telling Us To Load CairoMakie
@test_throws ErrorException plot_signatures(Sentinel2{60}, sigs)

using CairoMakie

# Should Run Now That CairoMakie is Loaded
fig = plot_signatures(Sentinel2{60}, sigs)