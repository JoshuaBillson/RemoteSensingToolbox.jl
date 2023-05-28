function _summarize_signatures(f, sigs::DataFrame, label::Symbol)
    @pipe DataFrames.groupby(sigs, label) |> DataFrames.combine(_, DataFrames.Not(label) .=> f)
end

function _extract_signatures(stack, shp, row)
    if length(names(stack)) > 25
        stacks = [RasterStack([stack[c] for c in part]...) for part in Iterators.partition(names(stack), 25)]
        sigs = [_extract_signatures(stack, shp, row) for stack in stacks]
        return reduce(hcat, sigs)
    else
        sigs = extract(stack, shp[row,:geometry]) |> collect
        cols = names(stack) |> length
        rows = length(sigs)
        return [sigs[r][c] for r in 1:rows, c in 2:cols+1]
    end
end