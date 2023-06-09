function _summarize_signatures(f, sigs::DataFrame, label::Symbol)
    @pipe DataFrames.groupby(sigs, label) |> DataFrames.combine(_, DataFrames.Not(label) .=> f)
end

function _extract_signatures(stack, shp, row)
    # Large Stacks
    if length(names(stack)) > 25 
        # Partition Stack Layers Into Chunks of 25
        stacks = [RasterStack([stack[c] for c in part]...) for part in Iterators.partition(names(stack), 25)]

        # Extract Signatures From Each Chunk
        ops = [_extract_signatures(stack, shp, row) for stack in stacks]

        # Merge Results
        return reduce(hcat, ops)

    # Small Stacks
    else
        return @pipe extract(stack, shp[row,:geometry]) |> DataFrame |> _[:,Not(:geometry)]
    end
end