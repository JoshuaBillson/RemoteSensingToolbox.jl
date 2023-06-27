function _parse_band(bands, filename::String)
    reg = "_" * capture(either(bands...), as="band") * "." * ["TIF", "tif", "jp2"] * END
    m = match(reg, filename)
    return !isnothing(m) ? (band=Symbol(m[:band]), src=filename) : missing
end

function _parse_landsat_qa(filename::String)
    reg = "_QA_PIXEL." * either("TIF", "tif") * END
    m = match(reg, filename)
    return !isnothing(m) ? (band=:QA, src=filename) : missing
end

function _chain_parse(filename::String, parsers...)
    return reduce((acc, p) -> ismissing(acc) ? p(filename) : acc, parsers; init=missing)
end
