struct Sentinel2A <: AbstractSensor
    bands::Dict{Symbol,Raster}
end

function Sentinel2A(dir::String; ext="jp2", lazy=true)
    files = [f for f in readdir(dir, join=true) if split(f, ".")[end] == ext]
    bands = map(x->split(x, "_")[end][1:3], files) .|> Symbol
    return @pipe Raster.(files; lazy=lazy, missingval=0) |>
    zip(bands, _) |> 
    Dict |> 
    Sentinel2A
end

function Base.getindex(X::Sentinel2A, i::Symbol)
    @assert i in keys(X.bands) "Band $i Not Found!"
    return X.bands[i]
end

blue(X::Sentinel2A) = X[:B02]

green(X::Sentinel2A) = X[:B03]

red(X::Sentinel2A) = X[:B04]

nir(X::Sentinel2A) = X[:B08]

swir1(X::Sentinel2A) = X[:B11]

swir2(X::Sentinel2A) = X[:B12]