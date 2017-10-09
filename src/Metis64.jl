module Metis64

    if isfile(joinpath(dirname(@__FILE__),"..","deps","deps.jl"))
        include("../deps/deps.jl")      # define libmetis and check it can be dlopen'd
    else
        error("Metis package not properly installed. Please run Pkg.build(\"Metis\")")
    end

    using Graphs,Compat                 # for AdjacencyList types
    using LightGraphs                   # metisform
    export
        partGraphKway,
        partGraphRecursive

    include("metis_h.jl")               # define constants
    include("util.jl")                  # metisform and testgraph functions


# """
# ```
# partGraphKway(G, nparts,
#               [, adjwgt, vwgt, vsize,
#                tpwgts, ubvec, options]) -> objval, part
# ```
#
# Partition a graph with multilevel k-way partitioning. See Metis
# documentation for more detail.
#
# Inputs:
#
# * `G` : Undirected graph. Can be an adjacency matrix (sparse or dense), a Graphs package adjacency list, or a LightGraphs package graph.
# * `nparts` : The number of parts to partition the graph.
# * `adjwgt` : Boolean indicating if edges are weighted. If true, `G` must be an adjacency matrix.
# * `vwgt` : The weights of the vertices.
# * `vsize` : The size of the vertices for computing the total communication volume.
# * `tpwgts` : Array of size `nparts` x `ncon` that specifies the desired weight for each partition and constraint.
# * `ubvec` : Array of size `ncon` that specifies the allowed load imbalance tolerance for each constraint.
# * `options` : Array of options.
#
# Outputs:
#
# * `objval` : The edge-cut or the total communication volume of the partitioning solution.
# * `part` : The partition vector of the graph.
#
# """
function partGraphKway(G, nparts, ::Type{T};
                           options::Array=-ones(METIS_NOPTIONS),
                           adjwgt::Bool=false,
                           vwgt::Array=[], vsize::Array=[],
                           tpwgts::Array=[], ubvec::Array=[],
                           ) where {T<:Integer}

    if !(T in [Int32 Int64])
        error("nparts must be either Int32 or Int64, but is " * string(T))
    end

    # Get adjacency structure of graph
    if adjwgt
        typeof(G)<:SparseMatrixCSC || error("weighted graphs must be represented in CSC format")
        n, xadj, adjncy, _adjwgt = metisform_weighted(G, T)
    else
         n, xadj, adjncy = metisform(G, T)
        _adjwgt = C_NULL
    end

    # Check parameters are valid
    nparts > 1 || error("nparts must be greater than one")
    length(vwgt)==0 || size(vwgt)==(n,) || error("vwgt must have n entries")
    length(vsize)==0 || size(vsize)==(n,) || error("vsize must have n entries")
    if length(tpwgts)>0
        ncon = convert(T, size(tpwgts)[1])
        size(tpwgts)==(ncon,nparts) || error("tpwgts must be an ncon x nparts array")
    else
        ncon = one(T)
    end
    length(ubvec)==0 || size(ubvec)==(ncon,) || error("ubvec must have ncon entries")
    length(options)==0 || size(options)==(METIS_NOPTIONS,) || error("options must have METIS_NOPTIONS entries")

    # Initialize partition parameters
    _vwgt = (length(vwgt)>0) ? round.(T, vwgt) : C_NULL
    _vsize = (length(vsize)>0) ? round.(T, vsize) : C_NULL

    _tpwgts = (length(tpwgts)>0) ? convert(Array{T==Int32 ? Cfloat : Cdouble}, tpwgts) : C_NULL
    _ubvec = (length(ubvec)>0) ? convert(Array{T==Int32 ? Cfloat : Cdouble}, ubvec) : C_NULL

    _options = (length(options)>0) ? convert(Array{T}, options) : C_NULL

    # Allocate memory for outputs
    part = Array{T}(n)
    objval = zeros(T, 1)

    #println("here, we go")
    # Call Metis partitioner
    if T==Int32
        err = ccall((:METIS_PartGraphKway, libmetis), Cint, # Last one is return value
                (Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint},
                 Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cfloat}, Ptr{Cfloat},
                 Ptr{Cint}, Ptr{Cint}, Ptr{Cint}),
                &n, &ncon, xadj, adjncy,
               _vwgt, _vsize, _adjwgt, &convert(T,nparts),
               _tpwgts, _ubvec, _options, objval, part)
    else
        err = ccall((:METIS_PartGraphKway, libmetis64), Clonglong, # Last one is return value
                (Ptr{Clonglong}, Ptr{Clonglong}, Ptr{Clonglong}, Ptr{Clonglong}, Ptr{Clonglong},
                 Ptr{Clonglong}, Ptr{Clonglong}, Ptr{Clonglong}, Ptr{Cdouble}, Ptr{Cdouble},
                 Ptr{Clonglong}, Ptr{Clonglong}, Ptr{Clonglong}),
                &n, &ncon, xadj, adjncy,
                _vwgt, _vsize, _adjwgt, &convert(T,nparts),
                _tpwgts, _ubvec, _options, objval, part)
    end

    part = part .+ 1

    # Return results
    return err, objval[1], part

end

function partGraphRecursive(G, nparts, ::Type{T};
                               options::Array=-ones(METIS_NOPTIONS),
                               adjwgt::Bool=false,
                               vwgt::Array=[], vsize::Array=[],
                               tpwgts::Array=[], ubvec::Array=[],
                               ) where {T<:Integer}
    if !(T in [Int32 Int64])
        error("nparts must be either Int32 or Int64")
    end

    # Get adjacency structure of graph
    if adjwgt
        typeof(G)<:SparseMatrixCSC || error("weighted graphs must be represented in CSC format")
        n, xadj, adjncy, _adjwgt = metisform_weighted(G, T)
    else
        n, xadj, adjncy = metisform(G, T)
        _adjwgt = C_NULL
    end

    # Check parameters are valid
    nparts > 1 || error("nparts must be greater than one")
    length(vwgt)==0 || size(vwgt)==(n,) || error("vwgt must have n entries")
    length(vsize)==0 || size(vsize)==(n,) || error("vsize must have n entries")
    if length(tpwgts)>0
        ncon = convert(T, size(tpwgts)[1])
        size(tpwgts)==(ncon,nparts) || error("tpwgts must be an ncon x nparts array")
    else
        ncon = one(T)
    end
    length(ubvec)==0 || size(ubvec)==(ncon,) || error("ubvec must have ncon entries")
    length(options)==0 || size(options)==(METIS_NOPTIONS,) || error("options must have METIS_NOPTIONS entries")

    # Initialize partition parameters
    _vwgt = (length(vwgt)>0) ? round.(T, vwgt) : C_NULL
    _vsize = (length(vsize)>0) ? round.(T, vsize) : C_NULL

    _tpwgts = (length(tpwgts)>0) ? convert(Array{T==Int32 ? Cfloat : Cdouble}, tpwgts) : C_NULL
    _ubvec = (length(ubvec)>0) ? convert(Array{T==Int32 ? Cfloat : Cdouble}, ubvec) : C_NULL

    _options = (length(options)>0) ? convert(Array{T}, options) : C_NULL

    part = Array{T}(n)
    objval = zeros(T, 1)
    if T==Int32
        err = ccall((:METIS_PartGraphRecursive, libmetis), Cint, # Last one is return value
                (Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint},
                 Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cfloat}, Ptr{Cfloat},
                 Ptr{Cint}, Ptr{Cint}, Ptr{Cint}),
                &n, &ncon, xadj, adjncy,
               _vwgt, _vsize, _adjwgt, &convert(T,nparts),
               _tpwgts, _ubvec, _options, objval, part)
    else
        err = ccall((:METIS_PartGraphRecursive, libmetis64), Clonglong, # Last one is return value
                (Ptr{Clonglong}, Ptr{Clonglong}, Ptr{Clonglong}, Ptr{Clonglong}, Ptr{Clonglong},
                 Ptr{Clonglong}, Ptr{Clonglong}, Ptr{Clonglong}, Ptr{Cdouble}, Ptr{Cdouble},
                 Ptr{Clonglong}, Ptr{Clonglong}, Ptr{Clonglong}),
                &n, &ncon, xadj, adjncy,
                _vwgt, _vsize, _adjwgt, &convert(T, nparts),
                _tpwgts, _ubvec, _options, objval, part)
    end

    part = part .+ 1

    return err, objval[1], part
end

end # module
