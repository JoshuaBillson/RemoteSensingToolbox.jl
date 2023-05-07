struct Landsat7 <: AbstractSensor
    bands::Dict{Symbol,Raster}
end
    
function Landsat7(dir::String; ext="TIF", lazy=true)
    # Read Files
    landsat_bands = [:B1, :B2, :B3, :B4, :B5, :B6, :B7]
    files = [f for f in readdir(dir, join=true) if split(f, ".")[end] == ext]

    # Filter Files
    files = filter(x->split(x, "_")[end][1:2] in string.(landsat_bands), files)

    # Read Bands
    bands = map(x->split(x, "_")[end][1:2], files) .|> Symbol

    # Construct Landsat7
    @pipe Raster.(files; lazy=lazy) |>
    zip(bands, _) |> 
    Dict |> 
    Landsat7
end

function Base.getindex(X::Landsat7, i::Symbol)
    @assert i in keys(X.bands) "Band $i Not Found!"
    return X.bands[i]
end

blue(X::Landsat7) = X[:B1]

green(X::Landsat7) = X[:B2]

red(X::Landsat7) = X[:B3]

nir(X::Landsat7) = X[:B4]

swir1(X::Landsat7) = X[:B5]

swir2(X::Landsat7) = X[:B7]