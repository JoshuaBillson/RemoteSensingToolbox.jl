"""
A struct for storing the band names and associated wavelengths of a particular sensor.

It is expected that instances of `AbstractSensor` implement a `BandSet` constructor.

The central wavelength for a given band can be recovered by calling the `BandSet`.

# Example
```julia-repl
julia> bandset = BandSet(Sentinel2A);
julia> bandset(:B8A)
842.0
```
"""
struct BandSet
    bands::Vector{Symbol}
    wavelengths::Vector{Float64}
end

function bandset(::Type{T}) where {T <: AbstractSensor}
    error("Error: BandSet not defined for '$(T.name.wrapper)'!")
end

function (bandset::BandSet)(band::Symbol)
    return @pipe zip(bandset.bands, bandset.wavelengths) |> Dict |> _[band]
end

function (bandset::BandSet)(band::String)
    return bandset(Symbol(band))
end
