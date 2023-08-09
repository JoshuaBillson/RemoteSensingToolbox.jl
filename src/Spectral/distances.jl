function spectral_angle(x::Vector{<:AbstractFloat}, y::Vector{<:AbstractFloat})
    numerator = dot(x, y)
    denomenator = norm(x) * norm(y)
    return acos(numerator / denomenator)
end

function spectral_angle(x, y)
    return spectral_angle(Float32.(x), Float32.(y))
end

function euclidean_distance(x::Vector{<:AbstractFloat}, y::Vector{<:AbstractFloat})
    return norm(x .- y)
end

function euclidean_distance(x, y)
    return euclidean_distance(Float32.(x), Float32.(y))
end

function likelihood(x::Vector{T}, y::Vector{T}, probability, Σ) where {T <: AbstractFloat}
    Δ = x .- y
    
    return log(probability) - (T(0.5) * logdet(Σ)) - (T(0.5) * dot(Δ, LinearAlgebra.inv(Σ) * Δ))
end

function maximum_likelihood(x, y)
    return maximum_likelihood(Float32.(x), Float32.(y))
end