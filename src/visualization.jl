struct TrueColor end

struct ColorInfrared end

struct SWIR end

struct Agriculture end

struct Geology end

function visualize(r::AbstractArray, g::AbstractArray, b::AbstractArray; lower=0.02, upper=0.98)
    visualize(r .* 1.0f0, g .* 1.0f0, b .* 1.0f0; lower=lower, upper=upper)
end
    
function visualize(r::AbstractArray{Float32}, g::AbstractArray{Float32}, b::AbstractArray{Float32}; lower=0.02, upper=0.98)
    @pipe map(img->linear_stretch(img, lower, upper), align_rasters(r, g, b)) |>
    cat(extract_raster_data.(_)..., dims=3) |>
    raster_to_image
end

function visualize(g::AbstractArray; lower=0.02, upper=0.98)
    visualize(g .* 1.0f0; lower=lower, upper=upper)
end
    
function visualize(g::AbstractArray{Float32}; lower=0.02, upper=0.98)
    @pipe efficient_read(g) |>
    linear_stretch(_, lower, upper) |>
    extract_raster_data |>
    raster_to_image
end

function visualize(img::AbstractSensor, ::Type{TrueColor}; lower=0.02, upper=0.98)
    visualize(red(img), green(img), blue(img), lower=lower, upper=upper)
end

function visualize(img::AbstractSensor, ::Type{ColorInfrared}; lower=0.02, upper=0.98)
    visualize(nir(img), red(img), green(img), lower=lower, upper=upper)
end

function visualize(img::AbstractSensor, ::Type{SWIR}; lower=0.02, upper=0.98)
    visualize(swir2(img), swir1(img), red(img), lower=lower, upper=upper)
end

function visualize(img::AbstractSensor, ::Type{Agriculture}; lower=0.02, upper=0.98)
    visualize(swir1(img), nir(img), blue(img), lower=lower, upper=upper)
end

function visualize(img::AbstractSensor, ::Type{Geology}; lower=0.02, upper=0.98)
    visualize(swir2(img), swir1(img), blue(img), lower=lower, upper=upper)
end