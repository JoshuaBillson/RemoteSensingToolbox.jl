using Test, Statistics
using RemoteSensingToolbox, Rasters, ArchGDAL
using DataDeps, Fetch, Images
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
sentinel = Sentinel2{20}(datadep"S2B_MSIL2A_20200804T183919_N0214_R070_T11UPT_20200804T230343")

# Test Indices
for index in [mndwi, ndwi, ndvi, ndmi, nbri, ndbi, savi]
    result = index(sentinel)
    @test result isa AbstractArray{Float32}
    @test (result |> skipmissing |> maximum) <= 1.0f0
    @test (result |> skipmissing |> minimum) >= -1.0f0
    @test visualize(result) isa AbstractArray{Gray{N0f8}}
end