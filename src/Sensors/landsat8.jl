struct Landsat8 <: AbstractSensor
    bands::Dict{Symbol,Raster}
end
    
function Landsat8(dir::String; ext="TIF", lazy=true)
    # Read Files
    landsat_bands = [:B1, :B2, :B3, :B4, :B5, :B6, :B7]
    files = [f for f in readdir(dir, join=true) if split(f, ".")[end] == ext]

    # Filter Files
    files = filter(x->split(x, "_")[end][1:2] in string.(landsat_bands), files)
    files = filter(x->!contains(x, "_B10"), files)

    # Read Bands
    bands = map(x->split(x, "_")[end][1:2], files) .|> Symbol

    # Construct Landsat8
    @pipe Raster.(files; lazy=lazy) |>
    zip(bands, _) |> 
    Dict |> 
    Landsat8
end

function Base.getindex(X::Landsat8, i::Symbol)
    @assert i in keys(X.bands) "Band $i Not Found!"
    return X.bands[i]
end

blue(X::Landsat8) = X[:B2]

green(X::Landsat8) = X[:B3]

red(X::Landsat8) = X[:B4]

nir(X::Landsat8) = X[:B5]

swir1(X::Landsat8) = X[:B6]

swir2(X::Landsat8) = X[:B7]