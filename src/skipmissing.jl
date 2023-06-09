struct RasterStackIterator{T,I,E}
    stack::T
    indices::Vector{I}
    eltype::Type{E}
end

function RasterStackIterator(rs::RasterStack; skipmissingvals=true)
    if skipmissingvals
        indices = @pipe [skipmissing(rs[b]) for b in names(rs)] |> eachindex.(_) |> BitSet.(_) |> intersect(_...) |> collect
        return RasterStackIterator(rs, indices, rs[1] |> typeof)
    else
        indices = first(rs) |> eachindex |> collect
        return RasterStackIterator(rs, indices, _rasterstack_eltype(rs::RasterStack))
    end
end

function Base.skipmissing(rs::RasterStack)
    return RasterStackIterator(rs)
end

function Base.Iterators.flatten(rs::RasterStack)
    return RasterStackIterator(rs; skipmissingvals=false)
end

function Base.getindex(X::RasterStackIterator{T,I,E}, i::I) where {T,I,E}
    !in(i, X.indices) && throw(MissingException)
    return X.stack[i]
end

function Base.getindex(X::RasterStackIterator, i)
    !in(i, Base.keys(X)) && throw(MissingException)
    return X.stack[i]
end

function Base.eachindex(X::RasterStackIterator)
    return X.indices
end

function Base.keys(X::RasterStackIterator)
    return @pipe first(X.stack) |> Base.keys |> @view(_[X.indices])
end

function Base.length(X::RasterStackIterator)
    Base.eachindex(X) |> length
end

function Base.iterate(iter::RasterStackIterator, state)
    length(iter) < state && return nothing
    index = iter.indices[state]
    return (@inbounds(iter.stack[index]), state + 1)
end

function Base.iterate(iter::RasterStackIterator)
    length(iter) == 0 && return nothing
    index = iter.indices[1]
    return (@inbounds(iter.stack[index]), 2)
end

Base.IteratorEltype(::Type{RasterStackIterator{T,I,E}}) where {T,I,E} = Base.IteratorEltype(T)

Base.eltype(::Type{RasterStackIterator{T,I,E}}) where {T,I,E} = E

function _rasterstack_eltype(rs::RasterStack)
    layers = Base.eltype(rs) |> keys
    types = Base.eltype(rs) |> collect
    return NamedTuple{layers, Tuple{types...}}
end

function RasterStackCustom(rasters, names; kwargs...)
    stacks = map(zip(rasters, names)) do (raster, name)
        if contains_bands(raster)
            names = Tuple(Symbol(name, :_band_, i) for i in 1:size(raster, 3))
            rasters = [raster[Rasters.Band(i)] for i in 1:size(raster, 3)]
            return Rasters.RasterStack(rasters..., name=names, kwargs...)
        else
            return Rasters.RasterStack(raster, name=name)
        end
    end
    return merge(stacks...)
end