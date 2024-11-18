@isdefined(RandVar) || include(string(@__DIR__, "/rand_vars.jl"))
@isdefined(Factor)  || include(string(@__DIR__, "/factors.jl"))


struct FactorGraph
	rvs::Dict{AbstractString, RandVar}
	rv_edges::Dict{RandVar, Set{Factor}}
	factors::Dict{AbstractString, Factor}
	factor_edges::Dict{Factor, Set{RandVar}}
	FactorGraph() = new(Dict(), Dict(), Dict(), Dict())
end

"""
	rvs(fg::FactorGraph)::Base.ValueIterator

Return all random variables in the given factor graph `fg`.
"""
function rvs(fg::FactorGraph)::Base.ValueIterator
	return values(fg.rvs)
end

"""
	numrvs(fg::FactorGraph)::Int

Return the number of random variables in the factor graph `fg`.
"""
function numrvs(fg::FactorGraph)::Int
	return length(keys(fg.rvs))
end

"""
	add_rv!(fg::FactorGraph, rv::RandVar)::Bool

Add the random variable `rv` to the factor graph `fg`.
Return `true` on success, else `false`.
"""
function add_rv!(fg::FactorGraph, rv::RandVar)::Bool
	has_rv(fg, name(rv)) && return false
	fg.rvs[name(rv)] = rv
	fg.rv_edges[rv] = Set()
	return true
end

"""
	has_rv(fg::FactorGraph, name::AbstractString)::Bool

Check whether the factor graph `fg` contains a random variable with name
`name`.
"""
function has_rv(fg::FactorGraph, name::AbstractString)::Bool
	return haskey(fg.rvs, name)
end

"""
	get_rv(fg::FactorGraph, name::AbstractString)::RandVar

Return the random variable with name `name` in `fg`.
"""
function get_rv(fg::FactorGraph, name::AbstractString)::RandVar
	return fg.rvs[name]
end

"""
	get_rvs(fg::FactorGraph, str::AbstractString)::Vector{RandVar}

Return all random variables in `fg` containg the string `str` in their name.
"""
function get_rvs(fg::FactorGraph, str::AbstractString)::Vector{RandVar}
	return [rv for rv in rvs(fg) if occursin(str, name(rv))]
end

"""
	rem_rv!(fg::FactorGraph, name::AbstractString)::Bool

Remove the random variable with name `name` from the factor graph `fg`.
Return `true` on success, else `false`.
"""
function rem_rv!(fg::FactorGraph, name::AbstractString)::Bool
	!has_rv(fg, name(rv)) && return false
	delete!(fg.rvs, name)
	return true
end

"""
	factors(fg::FactorGraph)::Base.ValueIterator

Return all factors in the given factor graph `fg`.
"""
function factors(fg::FactorGraph)::Base.ValueIterator
	return values(fg.factors)
end

"""
	numfactors(fg::FactorGraph)::Int

Return the number of factors in the factor graph `fg`.
"""
function numfactors(fg::FactorGraph)::Int
	return length(keys(fg.factors))
end

"""
	add_factor!(fg::FactorGraph, f::Factor)::Bool

Add the factor `f` to the factor graph `fg`.
Return `true` on success, else `false`.
"""
function add_factor!(fg::FactorGraph, f::Factor)::Bool
	has_factor(fg, name(f)) && return false
	fg.factors[name(f)] = f
	fg.factor_edges[f] = Set()
	return true
end

"""
	has_factor(fg::FactorGraph, name::AbstractString)::Bool

Check whether the factor graph `fg` contains the factor with name `name`.
"""
function has_factor(fg::FactorGraph, name::AbstractString)::Bool
	return haskey(fg.factors, name)
end

"""
	get_factor(fg::FactorGraph, name::AbstractString)::Factor

Return the factor with name `name` in `fg`.
"""
function get_factor(fg::FactorGraph, name::AbstractString)::Factor
	return fg.factors[name]
end

"""
	rem_factor!(fg::FactorGraph, name::AbstractString)::Bool

Remove the factor with name `name` from the factor graph `fg`.
Return `true` on success, else `false`.
"""
function rem_factor!(fg::FactorGraph, name::AbstractString)::Bool
	!has_factor(fg, name(f)) && return false
	delete!(fg.factors, name)
	return true
end

"""
	numnodes(fg::FactorGraph)::Int

Return the number of nodes (random variables and factors)
in the factor graph `fg`.
"""
function numnodes(fg::FactorGraph)::Int
	return numrvs(fg) + numfactors(fg)
end

"""
	edges(fg::FactorGraph, rv::RandVar)::Set{Factor}

Return all factors in the given factor graph `fg` that are connected
to the random variable `rv` via an edge.
"""
function edges(fg::FactorGraph, rv::RandVar)::Set{Factor}
	return get(fg.rv_edges, rv, Set())
end

"""
	edges(fg::FactorGraph, f::Factor)::Set{RandVar}

Return all random variables in the given factor graph `fg` that are
connected to the factor `f` via an edge.
"""
function edges(fg::FactorGraph, f::Factor)::Set{RandVar}
	return get(fg.factor_edges, f, Set())
end

"""
	add_edge!(fg::FactorGraph, rv::RandVar, f::Factor)::Bool

Add an edge between the random variable `rv` and the factor `f` to the
factor graph `fg`.
Return `true` on success, else `false`.
"""
function add_edge!(fg::FactorGraph, rv::RandVar, f::Factor)::Bool
	has_edge(fg, rv, f) && return false
	push!(fg.rv_edges[rv], f)
	push!(fg.factor_edges[f], rv)
	return true
end

"""
	add_edge!(fg::FactorGraph, f::Factor, rv::RandVar)::Bool

Add an edge between the random variable `rv` and the factor `f` to the
factor graph `fg`.
Return `true` on success, else `false`.
"""
function add_edge!(fg::FactorGraph, f::Factor, rv::RandVar)::Bool
	return add_edge!(fg, rv, f)
end

"""
	has_edge(fg::FactorGraph, rv::RandVar, f::Factor)::Bool

Check whether the factor graph `fg` contains an edge between the random
variable `rv` and the factor `f`.
"""
function has_edge(fg::FactorGraph, rv::RandVar, f::Factor)::Bool
	return f in edges(fg, rv) && rv in edges(fg, f)
end

"""
	has_edge(fg::FactorGraph, f::Factor, rv::RandVar)::Bool

Check whether the factor graph `fg` contains an edge between the random
variable `rv` and the factor `f`.
"""
function has_edge(fg::FactorGraph, f::Factor, rv::RandVar)::Bool
	return has_edge(fg, rv, f)
end

"""
	rem_edge!(fg::FactorGraph, rv::RandVar, f::Factor)::Bool

Remove the edge between the random variable `rv` and the factor `f` from
the factor graph `fg`.
Return `true` on success, else `false`.
"""
function rem_edge!(fg::FactorGraph, rv::RandVar, f::Factor)::Bool
	!has_edge(fg, rv, f) && return false
	delete!(fg.rv_edges[rv], f)
	delete!(fg.factor_edges[f], rv)
	return true
end

"""
	rem_edge!(fg::FactorGraph, f::Factor, rv::RandVar)::Bool

Remove the edge between the random variable `rv` and the factor `f` from
the factor graph `fg`.
Return `true` on success, else `false`.
"""
function rem_edge!(fg::FactorGraph, f::Factor, rv::RandVar)::Bool
	return rem_edge!(fg, rv, f)
end

"""
	unknown_factors(fg::FactorGraph)::Vector{Factor}

Return all unknown (missing) factors in `fg`.
"""
function unknown_factors(fg::FactorGraph)::Vector{Factor}
	return [f for f in factors(fg) if is_unknown(f)]
end

"""
	is_valid(fg::FactorGraph)::Bool

Check whether the factor graph `fg` is valid.
"""
function is_valid(fg::FactorGraph)::Bool
	for f in factors(fg)
		is_valid(f) || return false
		length(edges(fg, f)) == length(rvs(f)) || return false
		all(x -> has_edge(fg, f, x), rvs(f)) || return false
	end
	return true
end

"""
	reachable(fg::FactorGraph, from::RandVar, to::RandVar)::Bool

Check whether a random variable `to` is reachable from a random variable
`from` in a factor graph `fg`.
"""
function reachable(fg::FactorGraph, from::RandVar, to::RandVar)::Bool
	from == to && return true

	visited = Set{Union{RandVar, Factor}}()
	queue::Vector{Union{RandVar, Factor}} = [from]
	while !isempty(queue)
		node = pop!(queue)
		push!(visited, node)
		for nbr in edges(fg, node)
			isa(nbr, RandVar) && nbr == to && return true
			!(nbr in visited) && push!(queue, nbr)
		end
	end
	return false
end

"""
	is_connected(fg::FactorGraph)::Bool

Check whether the factor graph `fg` is connected (i.e., every random
variable is connected via a path to any other random variable).
"""
function is_connected(fg::FactorGraph)::Bool
	# TODO: Use a cache for efficiency
	for a in rvs(fg), b in rvs(fg)
		reachable(fg, a, b) || return false
	end
	return true
end

"""
	Base.deepcopy(fg::FactorGraph)::FactorGraph

Create a deep copy of `fg`.
"""
function Base.deepcopy(fg::FactorGraph)::FactorGraph
	fg_cpy = FactorGraph()

	for f in factors(fg)
		f_cpy = deepcopy(f)
		add_factor!(fg_cpy, f_cpy)
		for rv_cpy in rvs(f_cpy)
			if !haskey(fg_cpy.rvs, name(rv_cpy))
				add_rv!(fg_cpy, rv_cpy)
				add_edge!(fg_cpy, rv_cpy, f_cpy)
			else
				f_cpy_rvs = rvs(f_cpy)
				new_rv = fg_cpy.rvs[name(rv_cpy)]
				f_cpy_rvs[findfirst(rv -> rv == rv_cpy, f_cpy_rvs)] = new_rv
				add_edge!(fg_cpy, new_rv, f_cpy)
			end
		end
	end

	# If there are random variables not connected to any factor,
	# they are added now (without edges, as they are unconnected)
	rv_names = map(rv -> name(rv), rvs(fg_cpy))
	for rv in rvs(fg)
		if !(name(rv) in rv_names)
			add_rv!(fg_cpy, deepcopy(rv))
		end
	end

	return fg_cpy
end

"""
	Base.:(==)(fg1::FactorGraph, fg2::FactorGraph)::Bool

Check whether two factor graphs `fg1` and `fg2` are identical.
"""
function Base.:(==)(fg1::FactorGraph, fg2::FactorGraph)::Bool
	sort(collect(keys(fg1.rvs))) == sort(collect(keys(fg2.rvs))) || return false
	sort(collect(keys(fg1.factors))) == sort(collect(keys(fg2.factors))) || return false

	rvk1 = sort(collect(keys(fg1.rv_edges)), by=rv->name(rv))
	rvk2 = sort(collect(keys(fg2.rv_edges)), by=rv->name(rv))
	rvk1 == rvk2 || return false
	for i in eachindex(rvk1)
		fg1.rv_edges[rvk1[i]] == fg2.rv_edges[rvk2[i]] || return false
	end

	fk1 = sort(collect(keys(fg1.factor_edges)), by=f->name(f))
	fk2 = sort(collect(keys(fg2.factor_edges)), by=f->name(f))
	fk1 == fk2 || return false
	for i in eachindex(fk1)
		fg1.factor_edges[fk1[i]] == fg2.factor_edges[fk2[i]] || return false
	end

	return true
end

"""
	Base.show(io::IO, fg::FactorGraph)

Show the factor graph `fg` in the given output stream `io`.
"""
function Base.show(io::IO, fg::FactorGraph)
	println(io, "FactorGraph:")
	println(io, "\tRVs: $([name(x) for x in rvs(fg)])")
	println(io, "\tFactors: $([name(x) for x in factors(fg)])")
	pad_size = 12
	for f in factors(fg)
		println(io, "\t\tPotentials for factor $(name(f)):")
		if isempty(f.potentials)
			println(io, "\t\tMissing")
			continue
		end
		h = string("\t\t| ", join(map(x -> lpad(name(x), pad_size), rvs(f)), " | "))
		h = string(h, " | ", lpad(name(f), pad_size), " |")
		println(io, h)
		println(io, string("\t\t|", repeat("-", length(h) - 4), "|"))
		for c in sort(collect(keys(f.potentials)), rev=true)
			p = f.potentials[c]
			print(io, string("\t\t| ", join(map(x -> lpad(x, pad_size), split(c, ",")), " | ")))
			print(io, string(" | ",lpad(p, pad_size), " |", "\n"))
		end
		print(io, "\n")
	end
	print(io, "\tEdges: ")
	rvs_arr = collect(rvs(fg))
	for i in eachindex(rvs_arr)
		rv = rvs_arr[i]
		sep = i == length(rvs_arr) ? "" : ", "
		print(io, join([string(rv, " - ", x) for x in fg.rv_edges[rv]], ", "))
		print(io, isempty(fg.rv_edges[rv]) ? "" : sep)
	end
end