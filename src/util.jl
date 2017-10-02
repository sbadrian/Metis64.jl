"""
Flatten a vector of vectors
"""
function flatten{T}(x::Vector{Vector{T}})
    out = T[]
    for y in x
        append!(out, y)
    end
    out
end

"""
```
metisform(G) -> n, xadj, adjncy
```

Represent an undirected, unweighted graph `G` in form required for
Metis functions. `G` can be an adjacency matrix (sparse or dense), an
adjacency list from the Graphs package, or a graph from the the
LightGraphs package.  `n` is the number of vertices, `xadj` is an
array of 0-based column pointers, and `adjncy` is an array of 0-based
row indices.
"""
# Convert abstract matrix to Metis form
function metisform{T,N}(m::AbstractMatrix{N}, ::Type{T})
    metisform(convert(SparseMatrixCSC{N,T},m)n, T)
end

# Convert CSC matrix to METIS form
function metisform{T}(m::SparseMatrixCSC, ::Type{T})
    issymmetric(m) || ishermitian(m) || error("m must be symmetric or Hermitian")

    # Copy m.rowval and m.colptr to T vectors and drop diagonal elements
    adjncy = @compat sizehint!(T[],nnz(m))
    xadj = zeros(T,m.n+1)
    for j in 1:m.n
        count = 0
        for k in m.colptr[j] : (m.colptr[j+1] - 1)
            i = m.rowval[k]
            if i != j
                count += 1
                push!(adjncy,i-1)
            end
        end
        xadj[j+1] = xadj[j] + count
    end
    convert(T,m.n),xadj,adjncy
end

# Convert Graphs.GenericAdjacencyList to Metis form
function metisform{T}(al::Graphs.GenericAdjacencyList, ::Type{T})
    !Graphs.is_directed(al) || error("Metis functions require undirected graphs")
    @compat isa(al.vertices,UnitRange) && first(al.vertices) == 1 || error("Vertices must be numbered from 1")
    @compat length(al.adjlist), round(T, cumsum(vcat(0, map(length, al.adjlist)))),
        round(T, flatten(al.adjlist)) .- one(T)
end

# Convert LightGraphs.Graph to Metis form
function metisform{T}(g::LightGraphs.Graph, ::Type{T})
    n = convert(T,nv(g))
    xadj = zeros(T,n + 1)
    adjncy = sizehint!(T[],2*ne(g))
    for i in 1:n
        ein = [convert(T,dst(x)-1) for x in LightGraphs.out_edges(g, i)]
        xadj[i + 1] = xadj[i] + length(ein)
        append!(adjncy,ein)
    end
    n, xadj, adjncy
end

"""
```
metisform_weighted(G) -> n, xadj, adjncy, adjwgt
```

Represent an undirected, weighted graph `G` in form required for Metis
functions. `G` should be an adjacency matrix (sparse or dense).  `n`
is the number of vertices, `xadj` is an array of 0-based column
pointers, `adjncy` is an array of 0-based row indices, and `adjwgt` is
an array of edge weights. Edge weights are rounded to the nearest
integer since Metis requires integer edge weights.
"""
# Convert abstract matrix to Metis form
function metisform_weighted{T,N}(m::AbstractMatrix{N}, ::Type{T})
    metisform_weighted(convert(SparseMatrixCSC{N,T},m), T)
end

# Convert CSC matrix to Metis form
function metisform_weighted{T}(m::SparseMatrixCSC, ::Type{T})
    issymmetric(m) || ishermitian(m) || error("m must be symmetric or Hermitian")

    # copy m.rowvalm, m.colptr, and m.nzval to T vectors
    # and drop diagonal elements
    adjncy = @compat sizehint!(T[],nnz(m))
    adjwgt = @compat sizehint!(T[],nnz(m))
    xadj = zeros(T,m.n+1)
    for j in 1:m.n
        count = 0
        for k in m.colptr[j] : (m.colptr[j+1] - 1)
            i = m.rowval[k]
            if i != j
                count += 1
                push!(adjncy,i-1)
                push!(adjwgt,round(T,m[i,j]))
            end
        end
        xadj[j+1] = xadj[j] + count
    end
    convert(T,m.n),xadj,adjncy,adjwgt
end

"""
```
testgraph(nm) -> Graphs.GenericAdjacencyList
```

Load a file in the `Metis.jl/graphs/` directory and construct a
graph. `nm` should be the file name, excluding the `.graph` file
extension.
"""
# Load test graph
function testgraph(nm::String)
    pathnm = joinpath(dirname(@__FILE__), "..", "graphs", string(nm, ".graph"))
    ff = open(pathnm, "r")
    nvert, nedge = map(t -> parse(Int, t), split(readline(ff)))
    adjlist = Array(Vector{Int32}, nvert)
    for i in 1:nvert adjlist[i] = map(t -> parse(Int32, t), split(readline(ff))) end
    close(ff)
    @compat GenericAdjacencyList{Int32,UnitRange{Int32},Vector{Vector{Int32}}}(false,
                                                                    map(Int32, 1:nvert),
                                                                    nedge,
                                                                    adjlist)
end
