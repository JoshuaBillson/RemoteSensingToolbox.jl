using Test, Statistics
using RemoteSensingToolbox, Rasters, ArchGDAL
using DataFrames, GeoDataFrames, DataDeps, Fetch
using Pipe: @pipe

ENV["DATADEPS_ALWAYS_ACCEPT"] = true
ENV["DATADEPS_LOAD_PATH"] = joinpath(pwd(), "data")

# Download Data
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

# Load Sentinel
src = Sentinel2{60}(datadep"S2B_MSIL2A_20200804T183919_N0214_R070_T11UPT_20200804T230343")
sentinel = @pipe RasterStack(src) |> decode(Sentinel2{60}, _)

# Read Shapefile
shp = GeoDataFrames.read("data/landcover/landcover.shp")

# Extract Signatures
sigs = extract_signatures(mean, sentinel, shp, :MC_name) |> DataFrame
println(sigs)

# Should Throw Error Telling Us To Load CairoMakie
@test_throws ErrorException plot_signatures(Sentinel2{60}, sigs)

using CairoMakie

# Should Run Now That CairoMakie is Loaded
fig = plot_signatures(Sentinel2{60}, sigs)