@compat abstract type AbstractDecisionRule{S<:Grid,T<:Grid,nx} end

function Base.show(io::IO, dr::AbstractDecisionRule)
    println(io, typeof(dr))
end

outdim(dr::AbstractDecisionRule{<:Grid,<:Grid,nx}) where nx = nx


# ---------------------- #
# Constant decision rule #
# ---------------------- #

@compat type ConstantDecisionRule{nx} <: AbstractDecisionRule{EmptyGrid,EmptyGrid,nx}
    constants::Vector{Float64}
end

function ConstantDecisionRule(constants::Vector{Float64})
    nx = length(constants)
    ConstantDecisionRule{nx}(constants)
end

function ConstantDecisionRule{nx}(constants::Value{nx})
    ConstantDecisionRule{nx}(collect(constants))
end

(dr::ConstantDecisionRule)(x::AbstractVector) = dr.constants
(dr::ConstantDecisionRule)(x::AbstractMatrix) = repmat(dr.constants', size(x, 1), 1)
(dr::ConstantDecisionRule)(x::AbstractVector, y::AbstractVector) = dr.constants
(dr::ConstantDecisionRule)(x::AbstractVector, y::AbstractMatrix) = repmat(dr.constants', size(y, 1), 1)
(dr::ConstantDecisionRule)(x::AbstractMatrix, y::AbstractVector) = repmat(dr.constants', size(x, 1), 1)
(dr::ConstantDecisionRule)(x::AbstractMatrix, y::AbstractMatrix) = repmat(dr.constants', size(x, 1), 1)
(dr::ConstantDecisionRule)(i::Int, x::Union{AbstractVector,AbstractMatrix}) = dr(x)
(dr::ConstantDecisionRule)(i::Int, j::Int, x::Union{AbstractVector,AbstractMatrix}) = dr(x)

# ------------------------------ #
# 2-dimensional Taylor Expansion #
# ------------------------------ #

@compat type BiTaylorExpansion{nx} <: AbstractDecisionRule{EmptyGrid,EmptyGrid,nx}
    m0::Vector{Float64}
    s0::Vector{Float64}
    x0::Vector{Float64}
    x_m::Matrix{Float64}
    x_s::Matrix{Float64}
end

(dr::BiTaylorExpansion)(m::AbstractVector, s::AbstractVector) = dr.x0 + dr.x_m*(m-dr.m0) + dr.x_s*(s-dr.s0)
(dr::BiTaylorExpansion)(m::AbstractMatrix, s::AbstractVector) = vcat([(dr(m[i, :], s))' for i=1:size(m, 1) ]...)
(dr::BiTaylorExpansion)(m::AbstractVector, s::AbstractMatrix) = vcat([(dr(m, s[i, :]))' for i=1:size(s, 1) ]...)
(dr::BiTaylorExpansion)(m::AbstractMatrix, s::AbstractMatrix) = vcat([(dr(m[i, :], s[i, :]))' for i=1:size(m, 1) ]...)
