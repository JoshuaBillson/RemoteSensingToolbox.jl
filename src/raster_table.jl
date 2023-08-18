mutable struct RasterTable <: Tables.AbstractColumns
    layers::Vector{Symbol}
    cols::Vector{Vector}
end

function _dim_cols(raster)
    ds = Iterators.product(dims(raster)...)
    xs = @pipe map(first, ds) |> reshape(_, :)
    ys = @pipe map(x -> x[2], ds) |> reshape(_, :)
    return (xs, ys)
end

function _replace_missing(raster::AbstractRaster)
    m = missingval(raster)
    r = reshape(raster, :)
    return ismissing(m) ? ifelse.(ismissing.(r), missing, r) : ifelse.(r .== m, missing, r)
end

function RasterTable(raster::AbstractRasterStack)
    layers = keys(raster) |> collect
    cols = [_replace_missing(raster[layer]) for layer in layers]
    return RasterTable(layers, cols)
end

function RasterTable(raster::AbstractRaster)
    stack = any(isa.(dims(raster), Rasters.Band)) ? RasterStack(raster, layersfrom=Rasters.Band) : RasterStack(raster)
    return RasterTable(stack)
end

function RasterTable(rasters::Vararg{Union{<:AbstractRasterStack, <:AbstractRaster}})
    DimensionalData.comparedims(rasters...)
    return merge(map(RasterTable, rasters)...)
end

function RasterTable(table::Tables.DictColumnTable)
    layers = Tables.columnnames(table) |> collect
    cols = collect(table)
    return RasterTable(layers, cols)
end

function RasterTable(table)
    return RasterTable(Tables.dictcolumntable(table))
end


#######################
# Tables.jl Interface #
#######################


lookup_column(table::RasterTable, col::Symbol) = findfirst(==(col), layers(table))

layers(table::RasterTable) = getfield(table, :layers)

cols(table::RasterTable) = getfield(table, :cols)

Tables.istable(::Type{<:RasterTable}) = true

Tables.schema(table::RasterTable) = Tables.Schema{nothing,nothing}(layers(table), [eltype(c) for c in cols(table)])

Tables.columnaccess(::Type{<:RasterTable}) = true

Tables.columns(table::RasterTable) = table

Tables.getcolumn(table::RasterTable, ::Type{T}, col::Int, nm::Symbol) where {T} = cols(table)[col]

Tables.getcolumn(table::RasterTable, nm::Symbol) = cols(table)[lookup_column(table, nm)]

Tables.getcolumn(table::RasterTable, i::Int) = cols(table)[i]

Tables.columnnames(table::RasterTable) = layers(table)

Tables.materializer(::Type{<:RasterTable}) = Tables.dictcolumntable


#####################
# Utility Functions #
#####################


function dropcolumn(table::RasterTable, col::Symbol)
    cols = filter(!=(col), Tables.columnnames(table))
    return table |> TableOperations.select(cols...) |> RasterTable
end

function transform_column(f, table::RasterTable, column::Symbol)
    op = Dict(column => (x -> ismissing(x) ? x : f(x)))
    return TableOperations.transform(table, op) |> Tables.columntable |> RasterTable
end

function dropmissing(table::RasterTable)
    # Find Indices Of Rows With No Missing Values
    nonmissing = @pipe [skipmissing(col) |> eachindex |> BitSet for col in table] |> intersect(_...) |> collect

    # Drop Missing Rows
    nonmissing_cols = [view(c, nonmissing) for c in table]

    # Narrow Types
    types = [typeof(first(c)) for c in nonmissing_cols]
    newcols = [zeros(t, length(nonmissing)) for t in types]

    # Copy Columns
    i = 1
    for col in nonmissing_cols
        newcols[i] .= col
        i += 1
    end

    # Return New RasterTable
    return RasterTable(layers(table), newcols)
end

function group_rows(table::RasterTable, by::Symbol)
    group_names = table[by] |> Set
    groups = [findall(==(group_name), table[by]) for group_name in group_names]
    return [RasterTable(Tables.subset(table, rows)) for rows in groups]
end

function fold_rows(f, table::RasterTable, by::Symbol)
    # Divide Table Into Groups
    groups = group_rows(table, by)

    # Get Group Labels
    labels = [first(g.label) for g in groups]

    # Get Group Values
    data = [Tables.matrix(g) for g in dropcolumn.(groups, by)]
    results = [dropdims(mapslices(f, x, dims=(1,)), dims=1) for x in data]

    # Return RasterTable
    layers = vcat([by], filter(!=(by), Tables.columnnames(table)))
    rows = [vcat(l, r) for (l, r) in zip(labels, results)]
    cols = [OrderedDict([(l => v) for (l, v) in zip(layers, row)]) for row in rows]
    return RasterTable(cols)
end

function Base.merge(tables::Vararg{RasterTable})
    new_layers = reduce(vcat, layers.(tables))
    new_cols = reduce(vcat, cols.(tables))
    return RasterTable(new_layers, new_cols)
end
