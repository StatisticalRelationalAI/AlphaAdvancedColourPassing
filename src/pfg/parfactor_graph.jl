@isdefined(PRV)         || include(string(@__DIR__, "/prvs.jl"))
@isdefined(Parfactor)   || include(string(@__DIR__, "/parfactors.jl"))
@isdefined(FactorGraph) || include(string(@__DIR__, "/../fg/factor_graph.jl"))

struct ParfactorGraph
	prvs::Dict{AbstractString, PRV}
	prv_edges::Dict{PRV, Set{Parfactor}}
	parfactors::Dict{AbstractString, Parfactor}
	parfactor_edges::Dict{Parfactor, Set{PRV}}
	ParfactorGraph() = new(Dict(), Dict(), Dict(), Dict())
end

"""
	prvs(pfg::ParfactorGraph)::Base.ValueIterator

Return all PRVs in `pfg`.
"""
function prvs(pfg::ParfactorGraph)::Base.ValueIterator
	return values(pfg.prvs)
end

"""
	numprvs(pfg::ParfactorGraph)::Int

Return the number of PRVs in `pfg`.
"""
function numprvs(pfg::ParfactorGraph)::Int
	return length(keys(pfg.prvs))
end

"""
	add_prv!(pfg::ParfactorGraph, prv::PRV)::Bool

Add the PRV `prv` to `pfg`.
Return `true` if `prv` was successfully added, and `false` if `pfg` already
contains a PRV with the same name as `prv`.
"""
function add_prv!(pfg::ParfactorGraph, prv::PRV)::Bool
	has_prv(pfg, name(prv)) && return false
	pfg.prvs[name(prv)] = prv
	pfg.prv_edges[prv] = Set()
	return true
end

"""
	has_prv(pfg::ParfactorGraph, name::AbstractString)::Bool

Check whether `pfg` contains a PRV with name `name`.
"""
function has_prv(pfg::ParfactorGraph, name::AbstractString)::Bool
	return haskey(pfg.prvs, name)
end

"""
	get_prv(pfg::ParfactorGraph, name::AbstractString)::PRV

Return the PRV with name `name` in `pfg`.
"""
function get_prv(pfg::ParfactorGraph, name::AbstractString)::PRV
	return pfg.prvs[name]
end

"""
	rem_prv!(pfg::ParfactorGraph, name::AbstractString)::Bool

Remove the PRV with name `name` from `pfg`.
Return `true` if the PRV was successfully removed, and `false` if `pfg` does
not contain a PRV with name `name`.
"""
function rem_prv!(pfg::ParfactorGraph, name::AbstractString)::Bool
	!has_prv(pfg, name) && return false
	delete!(pfg.prvs, name)
	return true
end

"""
	parfactors(pfg::ParfactorGraph)::Base.ValueIterator

Return all parfactors in `pfg`.
"""
function parfactors(pfg::ParfactorGraph)::Base.ValueIterator
	return values(pfg.parfactors)
end

"""
	numparfactors(pfg::ParfactorGraph)::Int

Return the number of parfactors in `pfg`.
"""
function numparfactors(pfg::ParfactorGraph)::Int
	return length(keys(pfg.parfactors))
end

"""
	add_parfactor!(pfg::ParfactorGraph, f::Parfactor)::Bool

Add the parfactor `f` to `pfg`.
Return `true` if `f` was successfully added, and `false` if `pfg` already
contains a parfactor with the same name as `f`.
"""
function add_parfactor!(pfg::ParfactorGraph, f::Parfactor)::Bool
	has_parfactor(pfg, name(f)) && return false
	pfg.parfactors[name(f)] = f
	pfg.parfactor_edges[f] = Set()
	return true
end

"""
	has_parfactor(pfg::ParfactorGraph, name::AbstractString)::Bool

Check whether `pfg` contains a parfactor with name `name`.
"""
function has_parfactor(pfg::ParfactorGraph, name::AbstractString)::Bool
	return haskey(pfg.parfactors, name)
end

"""
	get_parfactor(pfg::ParfactorGraph, name::AbstractString)::Parfactor

Return the parfactor with name `name` in `pfg`.
"""
function get_parfactor(pfg::ParfactorGraph, name::AbstractString)::Parfactor
	return pfg.parfactors[name]
end

"""
	rem_parfactor!(pfg::ParfactorGraph, name::AbstractString)::Bool

Remove the parfactor with name `name` from `pfg`.
Return `true` if the parfactor was successfully removed, and `false` if `pfg`
does not contain a parfactor with name `name`.
"""
function rem_parfactor!(pfg::ParfactorGraph, name::AbstractString)::Bool
	!has_parfactor(pfg, name) && return false
	delete!(pfg.parfactors, name)
	return true
end

"""
	numnodes(pfg::ParfactorGraph)::Int

Return the number of nodes (i.e., the number of parfactors plus the number
of PRVs) in `pfg`.
"""
function numnodes(pfg::ParfactorGraph)::Int
	return numprvs(pfg) + numparfactors(pfg)
end

"""
	edges(pfg::ParfactorGraph, prv::PRV)::Set{Parfactor}

Return all parfactors that are connected to the PRV `prv` in `pfg`.
"""
function edges(pfg::ParfactorGraph, prv::PRV)::Set{Parfactor}
	return get(pfg.prv_edges, prv, Set())
end

"""
	edges(pfg::ParfactorGraph, f::Parfactor)::Set{PRV}

Return all PRVs that are connected to the parfactor `f` in `pfg`.
"""
function edges(pfg::ParfactorGraph, f::Parfactor)::Set{PRV}
	return get(pfg.parfactor_edges, f, Set())
end

"""
	add_edge!(pfg::ParfactorGraph, prv::PRV, f::Parfactor)::Bool

Add an edge between `prv` and `f` to `pfg`.
Return `true` if the edge was successfully added, and `false` if `pfg`
already contains the edge.
"""
function add_edge!(pfg::ParfactorGraph, prv::PRV, f::Parfactor)::Bool
	has_edge(pfg, prv, f) && return false
	push!(pfg.prv_edges[prv], f)
	push!(pfg.parfactor_edges[f], prv)
	return true
end

"""
	add_edge!(pfg::ParfactorGraph, f::Parfactor, prv::PRV)::Bool

Add an edge between `f` and `prv` to `pfg`.
Return `true` if the edge was successfully added, and `false` if `pfg`
already contains the edge.
"""
function add_edge!(pfg::ParfactorGraph, f::Parfactor, prv::PRV)::Bool
	return add_edge!(pfg, prv, f)
end

"""
	has_edge(pfg::ParfactorGraph, prv::PRV, f::Parfactor)::Bool

Check whether `pfg` contains an edge between `prv` and `f`.
"""
function has_edge(pfg::ParfactorGraph, prv::PRV, f::Parfactor)::Bool
	return f in edges(pfg, prv) && prv in edges(pfg, f)
end

"""
	has_edge(pfg::ParfactorGraph, f::Parfactor, prv::PRV)::Bool

Check whether `pfg` contains an edge between `f` and `prv`.
"""
function has_edge(pfg::ParfactorGraph, f::Parfactor, prv::PRV)::Bool
	return has_edge(pfg, prv, f)
end

"""
	rem_edge!(pfg::ParfactorGraph, prv::PRV, f::Parfactor)::Bool

Remove the edge between `prv` and `f` from `pfg`.
Return `true` if the edge was successfully removed, and `false` if `pfg`
does not contain the edge.
"""
function rem_edge!(pfg::ParfactorGraph, prv::PRV, f::Parfactor)::Bool
	!has_edge(pfg, prv, f) && return false
	delete!(pfg.prv_edges[prv], f)
	delete!(pfg.parfactor_edges[f], prv)
	return true
end

"""
	rem_edge!(pfg::ParfactorGraph, f::Parfactor, prv::PRV)::Bool

Remove the edge between `f` and `prv` from `pfg`.
Return `true` if the edge was successfully removed, and `false` if `pfg`
does not contain the edge.
"""
function rem_edge!(pfg::ParfactorGraph, f::Parfactor, prv::PRV)::Bool
	return rem_edge!(pfg, prv, f)
end

"""
	ground(pfg::ParfactorGraph)::FactorGraph

Ground the parfactor graph `pfg` and return the corresponding factor graph.

NOTE: This function is only implemented for parfactor graphs without any
constraints and counted random variables.
"""
function ground(pfg::ParfactorGraph)::FactorGraph
	fg = FactorGraph()

	for prv in prvs(pfg)
		@assert isnothing(counted_over(prv)) && isempty(counted_in(prv))
		doms = [domain(lv) for lv in logvars(prv)]
		for conf in Iterators.product(doms...)
			rv_name = string(name(prv), ".", join(conf, "."))
			add_rv!(fg, DiscreteRV(rv_name, range(prv)))
		end
	end

	for pf in parfactors(pfg)
		@assert isempty(logvars(constraint(pf)))
		doms = Dict(lv => domain(lv) for lv in logvars(pf))
		doms_rev = Dict()
		for lv in logvars(pf), d in domain(lv)
			doms_rev[d] = lv
		end

		idx = 1
		for conf in Iterators.product(values(doms)...)
			lv_d = Dict(doms_rev[d] => d for d in conf)
			rvs = Vector{DiscreteRV}()
			for prv in prvs(pf)
				lvs_joined = join([lv_d[lv] for lv in logvars(prv)], ".")
				push!(rvs, get_rv(fg, string(name(prv), ".", lvs_joined)))
			end
			f = DiscreteFactor(string(name(pf), "_", idx), rvs, [])
			f.potentials = pf.potentials
			add_factor!(fg, f)
			for rv in rvs
				add_edge!(fg, rv, f)
			end
			idx += 1
		end
	end

	return fg
end

function Base.show(io::IO, pfg::ParfactorGraph)
	println(io, "ParfactorGraph:")
	println(io, "\tPRVs: $([p for p in prvs(pfg)])")
	println(io, "\tParfactors: $([f for f in parfactors(pfg)])")
	pad_size = 12
	for f in parfactors(pfg)
		println(io, "\t\tPotentials for parfactor $(name(f)):")
		if isempty(f.potentials)
			println(io, "\t\tMissing")
			continue
		end
		h = string("\t\t| ", join(map(x -> lpad(string(x), pad_size), prvs(f)), " | "))
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
	prvs_arr = collect(prvs(pfg))
	for i in eachindex(prvs_arr)
		prv = prvs_arr[i]
		sep = i == length(prvs_arr) ? "" : ", "
		print(io, join([string(prv, " - ", x) for x in pfg.prv_edges[prv]], ", "))
		print(io, isempty(pfg.prv_edges[prv]) ? "" : sep)
	end
end