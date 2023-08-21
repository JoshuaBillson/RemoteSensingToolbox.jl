using RemoteSensingToolbox, Test, ArchGDAL, Shapefile, Tables
using Pipe: @pipe

# Load Sentinel
sentinel = @pipe read_bands(Sentinel2, "data/sentinel/") |> dn_to_reflectance(Sentinel2, _)

# Read Shapefile
shp = Shapefile.Table("data/landcover/landcover.shp") |> Tables.columntable

# Should Throw Error Telling Us To Load CairoMakie
@test_throws ErrorException plot_signatures(Sentinel2, sentinel, shp, :MC_name)

using CairoMakie

# Should Run Now That CairoMakie is Loaded
fig = plot_signatures(Sentinel2, sentinel, shp, :MC_name)