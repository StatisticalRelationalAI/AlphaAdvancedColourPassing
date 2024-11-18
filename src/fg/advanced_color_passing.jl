using Combinatorics, Multisets

@isdefined(FactorGraph)            || include(string(@__DIR__, "/factor_graph.jl"))
@isdefined(commutative_args_decor) || include(string(@__DIR__, "/commutative_args.jl"))
@isdefined(is_exchangeable_deft!)  || include(string(@__DIR__, "/is_exchangeable.jl"))

"""
	advanced_color_passing!(fg::FactorGraph, factor_colors = Dict{Factor, Int}(), use_alpha = false)::Tuple{Dict{RandVar, Int}, Dict{Factor, Int}, Dict{Factor, Vector{DiscreteRV}}, Dict{Factor, Dict{Set, Dict}}}

Apply advanced color passing to a given factor graph `fg`.
Return a tuple of four dictionaries, the first mapping each random variable
to a group of random variables, the second mapping each factor to a group
of factors, the third mapping each factor to a cache of commutative arguments,
and the fourth mapping each factor to a cache of histograms.
Set `use_alpha` to `true` to detect exchangeable factors up to a scalar alpha.

## References
M. Luttermann, T. Braun, R. Möller, and M. Gehrke.
Colour Passing Revisited: Lifted Model Construction with Commutative Factors.
AAAI, 2024.

## Examples
```jldoctest
julia> fg = FactorGraph();
julia> nc, fc, com_cache, h_cache = advanced_color_passing!(fg)
```
"""
function advanced_color_passing!(
	fg::FactorGraph,
	factor_colors = Dict{Factor, Int}(),
	use_alpha = false
)::Tuple{Dict{RandVar, Int}, Dict{Factor, Int}, Dict{Factor, Vector{DiscreteRV}}, Dict{Factor, Tuple{OrderedDict, Dict}}}
	node_colors = Dict{RandVar, Int}()
	hist_cache = Dict{Factor, Tuple{OrderedDict, Dict}}() # Cache for histograms (buckets)
	commutative_args_cache = Dict{Factor, Vector{DiscreteRV}}()

	initcolors_ccp!(node_colors, factor_colors, fg, hist_cache, use_alpha)

	while true
		changed = false
		f_signatures = Dict{Factor, Vector{Int}}()
		for f in factors(fg)
			f_signatures[f] = []
			for node in rvs(f)
				push!(f_signatures[f], node_colors[node])
			end
			push!(f_signatures[f], factor_colors[f])
		end

		changed |= assigncolors_ccp!(factor_colors, f_signatures, fg, hist_cache, use_alpha)

		rv_signatures = Dict{RandVar, Vector{Tuple{Int,Int}}}()
		for node in rvs(fg)
			rv_signatures[node] = []
			for f in edges(fg, node)
				if !haskey(commutative_args_cache, f)
					commutative_args_cache[f] = commutative_args_decor(f, hist_cache)
				end
				if node in commutative_args_cache[f]
					push!(rv_signatures[node], (factor_colors[f], 0))
				else
					push!(rv_signatures[node], (factor_colors[f], rvpos(f, node)))
				end
			end
			sort!(rv_signatures[node])
			push!(rv_signatures[node], (node_colors[node], 0))
		end

		changed |= assigncolors_ccp!(node_colors, rv_signatures, fg)

		!changed && break
	end

	return node_colors, factor_colors, commutative_args_cache, hist_cache
end

"""
	initcolors_ccp!(node_colors::Dict{RandVar, Int}, factor_colors::Dict{Factor, Int}, fg::FactorGraph, hist_cache::Dict{Factor, Tuple{OrderedDict, Dict}}, use_alpha = false)

Initialize the color dictionaries `node_colors` and `factor_colors` for the
factor graph `fg`.
"""
function initcolors_ccp!(
	node_colors::Dict{RandVar, Int},
	factor_colors::Dict{Factor, Int},
	fg::FactorGraph,
	hist_cache::Dict{Factor, Tuple{OrderedDict, Dict}},
	use_alpha = false
)
	assigncolors_ccp!(node_colors, Dict{RandVar, Vector{Tuple{Int, Int}}}(), fg)
	assigncolors_ccp!(factor_colors, Dict{Factor, Vector{Int}}(), fg, hist_cache, use_alpha)
end

"""
	assigncolors_ccp!(node_colors::Dict{RandVar, Int}, rv_signatures::Dict{RandVar, Vector{Tuple{Int, Int}}}, fg::FactorGraph)::Bool

Re-assign colors to the random variables in `fg` based on the signatures
`rv_signatures`.
"""
function assigncolors_ccp!(
	node_colors::Dict{RandVar, Int},
	rv_signatures::Dict{RandVar, Vector{Tuple{Int, Int}}},
	fg::FactorGraph
)::Bool
	colors = Dict()
	current_color = 0
	changed = false
	for rv in rvs(fg)
		key = isempty(rv_signatures) ? (range(rv), evidence(rv)) : rv_signatures[rv]
		if !haskey(colors, key)
			colors[key] = current_color
			current_color += 1
		end
		if haskey(node_colors, rv) && node_colors[rv] != colors[key]
			changed = true
		end
		node_colors[rv] = colors[key]
	end
	return changed
end

"""
	assigncolors_ccp!(factor_colors::Dict{Factor, Int}, f_signatures::Dict{Factor, Vector{Int}}, fg::FactorGraph, hist_cache::Dict{Factor, Tuple{OrderedDict, Dict}}, use_alpha = false)::Bool

Re-assign colors to the factors in `fg` based on the signatures `f_signatures`.
"""
function assigncolors_ccp!(
	factor_colors::Dict{Factor, Int},
	f_signatures::Dict{Factor, Vector{Int}},
	fg::FactorGraph,
	hist_cache::Dict{Factor, Tuple{OrderedDict, Dict}},
	use_alpha = false
)::Bool
	colors = Dict()
	current_color = numrvs(fg)
	current_groups = Dict()
	changed = false
	key = nothing
	for f in factors(fg)
		if isempty(f_signatures)
			found_match = false
			for f_group in values(current_groups)
				f2 = f_group[1] # Guaranteed to have at least one element
				has_same_arg_types(f, f2) || continue
				if is_exchangeable_deft!(f2, f, hist_cache, use_alpha)
					key = potentials(f2)
					found_match = true
					break
				end
			end
			# No match found
			!found_match && (key = potentials(f))
			if !haskey(current_groups, key)
				current_groups[key] = []
			end
			push!(current_groups[key], f)
		else
			key = f_signatures[f]
		end
		if !haskey(colors, key)
			colors[key] = current_color
			current_color += 1
		end
		if haskey(factor_colors, f) && factor_colors[f] != colors[key]
			changed = true
		end
		factor_colors[f] = colors[key]
	end
	return changed
end

"""
	has_same_arg_types(f1::Factor, f2::Factor)::Bool

Check whether the arguments of `f1` and `f2` have the same types, i.e.,
a bijection between the arguments of `f1` and `f2` exists that maps
each argument of `f1` to an argument of `f2` with the same range.
"""
function has_same_arg_types(f1::Factor, f2::Factor)::Bool
	length(rvs(f1)) == length(rvs(f2)) || return false
	rvsf2 = copy(rvs(f2))
	for rv1 in rvs(f1)
		for rv2 in rvsf2
			if range(rv1) == range(rv2)
				deleteat!(rvsf2, findfirst(x -> x == rv2, rvsf2))
				break
			end
		end
	end
	return isempty(rvsf2)
end