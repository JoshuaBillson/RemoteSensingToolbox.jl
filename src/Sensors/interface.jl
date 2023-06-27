"""
    blue(X::AbstractSensor)

Return the blue band for the given sensor.
"""
blue(::T) where {T <: AbstractSensor} = error("Error: Band 'blue' not defined for $(T.name.wrapper)!")

"""
    green(X::AbstractSensor)

Return the green band for the given sensor.
"""
green(::T) where {T <: AbstractSensor} = error("Error: Band 'green' not defined for $(T.name.wrapper)!")

"""
    red(X::AbstractSensor)

Return the red band for the given sensor.
"""
red(::T) where {T <: AbstractSensor} = error("Error: Band 'red' not defined for $(T.name.wrapper)!")

"""
    nir(X::AbstractSensor)

Return the nir band for the given sensor.
"""
nir(::T) where {T <: AbstractSensor} = error("Error: Band 'nir' not defined for $(T.name.wrapper)!")

"""
    swir1(X::AbstractSensor)

Return the swir1 band for the given sensor.
"""
swir1(::T) where {T <: AbstractSensor} = error("Error: Band 'swir1' not defined for $(T.name.wrapper)!")

"""
    swir2(X::AbstractSensor)

Return the swir2 band for the given sensor.
"""
swir2(::T) where {T <: AbstractSensor} = error("Error: Band 'swir2' not defined for $(T.name.wrapper)!")

parse_files(::T, ::String) where {T <: AbstractSensor} = error("Error: Band 'parse_files' not defined for $(T.name.wrapper)!")

"""
    dn2rs(::Type{<:AbstractSensor})

Return the scale and offset required to convert DN to reflectance for the given sensor type.

# Example
```julia-repl
julia> dn2rs(Landsat8)
(scale = 2.75e-5, offset = -0.2)
```
"""
dn2rs(::Type{T}) where {T <: AbstractSensor} = error("Error: 'dn2rs' not defined for $(T.name.wrapper)!")

"""
    unwrap(X::AbstractSensor)
    unwrap(f, X::AbstractSensor, args...; kwargs...)

Remove the wrapped `RasterStack` from the `AbstractSensor` context.
"""
unwrap(::T) where {T <: AbstractSensor} = error("Error: 'unwrap' not defined for $(T.name.wrapper)!")

unwrap(f, X::AbstractSensor, args...; kwargs...) = @pipe unwrap(X) |> f(_, args...; kwargs...)

"""
    asraster(f, X::AbstractSensor, args...; kwargs...)

Operate on the AbstractSensor as if it was a regular `Rasters.RasterStack`, where `args` and `kwargs` are passed to `f`.
"""
asraster(f, X::T, args...; kwargs...) where {T <: AbstractSensor} = T.name.wrapper(f(unwrap(X), args...; kwargs...))

function read(::Type{T}, dir::String) where {T <: AbstractSensor}
    df = parse_files(T, dir)
    files = reduce(vcat, [df[df.band .== band, :src] for band in bandset(T).bands])
    bands = reduce(vcat, [df[df.band .== band, :band] for band in bandset(T).bands])
    return T(RasterStack(files, name=bands))
end