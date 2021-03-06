struct CompletePolyDR{S<:Grid,T<:Grid,nx} <: AbstractDecisionRule{S,T,nx}
    grid_exo::S
    grid_endo::T
    coefs::Vector{Matrix{Float64}}
    order::Int
end

#####
##### 1-argument decision rule
#####

function CompletePolyDR(
        grid_exo::EmptyGrid, grid_endo::Grid{ns},
        ::Union{Val{nx},Type{Val{nx}}}, order::Int=3
    ) where ns where nx
    coeffs = [Array{Float64}(BM.n_complete(ns, order), nx)]
    CompletePolyDR{EmptyGrid,typeof(grid_endo),nx}(grid_exo, grid_endo, coeffs, order)
end

function set_values!(
        dr::CompletePolyDR{<:G}, values::Vector{Matrix{Float64}}
    ) where G <: Union{<:EmptyGrid,<:UnstructuredGrid}
    B_grid = BM.complete_polynomial(nodes(dr.grid_endo), dr.order)
    for i in 1:length(values)
        A_ldiv_B!(dr.coefs[i], B_grid, values[i])
    end
end

function set_values!(
        dr::CompletePolyDR{<:G,<:Grid,nx},
        values::Vector{<:Array{Value{nx}}}
    ) where G <: Union{EmptyGrid,UnstructuredGrid} where nx
    B_grid = BM.complete_polynomial(nodes(dr.grid_endo), dr.order)

    if length(values) != length(dr.coefs)
        msg = "The length of values ($(length(values))) is not the same "
        msg *= "as the length of the coefficient Vector ($(length(dr.coefs)))"
        error(msg)
    end

    for i in 1:length(values)
        N = length(values[i])
        data = reinterpret(Float64, values[i], (nx, N))'
        A_ldiv_B!(dr.coefs[i], B_grid, data)
    end
end

function evaluate(dr::CompletePolyDR{<:EmptyGrid}, z::AbstractMatrix)
    B = BM.complete_polynomial(z, dr.order)
    B*dr.coefs[1]
end

function evaluate(dr::CompletePolyDR{<:EmptyGrid,<:Grid{d}}, points::Vector{Point{d}}) where d
    N = length(points)
    mat = reinterpret(Float64, points, (d, N))'
    evaluate(dr, mat)
end

####
#### UnstructuredGrid × CartesianGrid 2 continous arguments d.r.
####

function CompletePolyDR(
        grid_exo::S, grid_endo::Grid{ns},
        ::Union{Val{nx},Type{Val{nx}}}, order::Int=3
    ) where S <: UnstructuredGrid where ns where nx
    n_coefs = BM.n_complete(ns, order)
    coeffs = [Array{Float64}(n_coefs, nx) for i in 1:n_nodes(grid_exo)]
    CompletePolyDR{S,typeof(grid_endo),nx}(grid_exo, grid_endo, coeffs, order)
end

function evaluate(dr::CompletePolyDR{<:UnstructuredGrid}, i::Int, z::AbstractMatrix)
    @boundscheck begin
        n_funcs = length(dr.coefs)
        if i > n_funcs
            msg = "Only $n_funcs are known, but function $i was requested"
            throw(BoundsError(msg))
        end
    end
    B = BM.complete_polynomial(z, dr.order)
    B*dr.coefs[i]
end

function evaluate(dr::CompletePolyDR{<:UnstructuredGrid}, i::Int, z::Vector{Point{d}}) where d
    N = length(z)
    mat = reinterpret(Float64, z, (d, N))'
    evaluate(dr, i, mat)
end
