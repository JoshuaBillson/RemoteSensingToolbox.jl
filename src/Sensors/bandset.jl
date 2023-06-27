struct Interval
    lower::Float64
    upper::Float64
end

function Base.in(x::Number, i::Interval) 
    return i.lower <= x < i.upper
end

function midpoint(i::Interval)
    return i.lower + ((i.upper - i.lower) / 2)
end

"""
A struct for storing the band names and associated wavelengths of a particular sensor.

It is expected that instances of `AbstractSensor` implement a `BandSet` constructor.

The central wavelength for a given band can be recovered by index the `BandSet`.

# Example
```julia-repl
julia> bandset = BandSet(Sentinel2A);
julia> bandset[:B8A]
865.0
```
"""
struct BandSet
    bands::Vector{Symbol}
    wavelengths::Vector{Interval}
end

function bandset(::Type{T}) where {T <: AbstractSensor}
    error("Error: BandSet not defined for '$(T.name.wrapper)'!")
end

function Base.getindex(bandset::BandSet, i::Symbol)
    return @pipe zip(bandset.bands, bandset.wavelengths) |> Dict |> _[i] |> midpoint(_)
end

function Base.getindex(bandset::BandSet, i::String)
    return Base.getindex(bandset, Symbol(i))
end

function Base.getindex(bandset::BandSet, i::Number)
    band_index = in.(i, bandset.wavelengths) |> findall
    return isempty(band_index) ? nothing : bandset.bands[band_index]
end

function Base.in(x::Number, i::BandSet)
    return in.(x, i.wavelengths) |> any
end