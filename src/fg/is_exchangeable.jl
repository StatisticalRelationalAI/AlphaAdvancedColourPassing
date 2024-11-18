using OrderedCollections, Multisets

@isdefined(DiscreteFactor)  || include(string(@__DIR__, "/discrete_factor.jl"))
@isdefined(buckets_ordered) || include(string(@__DIR__, "/buckets.jl"))

"""
	is_exchangeable_deft!(f1::DiscreteFactor, f2::DiscreteFactor, hist_cache::Dict{Factor, Tuple{OrderedDict, Dict}}, use_alpha = false)::Bool

Check whether `f1` and `f2` are exchangeable and if so, permute the arguments
to obtain the same tables of potential mappings.
The implementation applies the DEFT algorithm to check whether the factors
are exchangeable, i.e., buckets are used both as a necessary and sufficient
condition.
Set `use_alpha` to `true` to detect exchangeable factors up to a scalar alpha.

## References
M. Luttermann, J. Machemer, and M. Gehrke.
Efficient Detection of Exchangeable Factors in Factor Graphs.
FLAIRS, 2024.
"""
function is_exchangeable_deft!(f1::DiscreteFactor, f2::DiscreteFactor, hist_cache::Dict{Factor, Tuple{OrderedDict, Dict}}, use_alpha = false)::Bool
	length(rvs(f1)) != length(rvs(f2)) && return false
	return validate_buckets!(f1, f2, hist_cache, use_alpha)
end

"""
	validate_buckets!(f1::DiscreteFactor, f2::DiscreteFactor, hist_cache::Dict{Factor, Tuple{OrderedDict, Dict}}, use_alpha = false)::Bool

Check whether `f1` and `f2` are exchangeable and if so, permute the arguments
of `f2` such that the tables of potential mappings of `f1` and `f2` are
identical.
"""
function validate_buckets!(f1::DiscreteFactor, f2::DiscreteFactor, hist_cache::Dict{Factor, Tuple{OrderedDict, Dict}}, use_alpha = false)::Bool
	!haskey(hist_cache, f1) && (hist_cache[f1] = buckets_ordered(f1, false))
	!haskey(hist_cache, f2) && (hist_cache[f2] = buckets_ordered(f2, true))

	buckets_f1, confs_f1 = hist_cache[f1]
	buckets_f2, confs_f2 = hist_cache[f2]

	# Possible swaps over the whole factor
	factor_set = Dict{Int, Set{Int}}()
	# Iterate all buckets to obtain positions of values that can be swapped
	# (in order of ascending degree of freedom)
	bucket_counter = 0
	alpha = use_alpha ? nothing : 1.0
	for (bucket, bucketvalues) in buckets_f2
		vals1 = buckets_f1[bucket]
		max_f1, max_f2 = maximum(buckets_f1[bucket]), maximum(bucketvalues)
		if use_alpha
			# Make sure alpha >= 1 to minimize floating point arithmetic errors
			new_alpha = (max_f1 > max_f2) ? max_f1 / max_f2 : max_f2 / max_f1
			(!isnothing(alpha) && alpha != new_alpha) && return false
			alpha = new_alpha
			(max_f1 > max_f2) && (bucketvalues *= alpha)
			(max_f1 < max_f2) && (vals1 *= alpha)
		end
		# If buckets contain different values, stop
		vals2 = Multiset(bucketvalues)
		vals2 != Multiset(vals1) && return false
		if vals2[first(vals2)] == length(vals2) # Number of occurrences of first()
			# All values identical, so all positions are possible
			bucket_set = Dict{Int, Set{Int}}(
				i => Set([j for j in 1:length(rvs(f2))]) for i in 1:length(rvs(f2))
			)
		else
			# Possible swaps over the current bucket
			bucket_set = Dict{Int, Set{Int}}()
			for (index, item) in enumerate(bucketvalues)
				# Possible swaps over the current item
				item_set = Dict{Int, Set{Int}}()
				# Row (assignment of arguments) of the current item in the table
				item_row = confs_f2[bucket][index]
				# Indices in other bucket where the current item is present
				index_in_other = findall(x -> x == item, vals1)
				for o_index in index_in_other
					other_row = confs_f2[bucket][o_index]
					positions = valuepositions(other_row)
					# Insert all possible swaps for the current item
					for (pos, value) in enumerate(item_row)
						for el in positions[value]
							!haskey(item_set, pos) && (item_set[pos] = Set{Int}())
							push!(item_set[pos], el)
						end
					end
				end

				if all(isempty, values(bucket_set))
					bucket_set = item_set
				else
					!build_intersection!(bucket_set, item_set) && return false
				end
			end
		end

		if all(isempty, values(factor_set))
			factor_set = bucket_set
		else
			!build_intersection!(factor_set, bucket_set) && return false
		end

		# Comment out to loop over all buckets instead of applying heuristic
		bucket_counter += 1
		bucket_counter >= 5 && break
	end

	function do_swaps!(curr_swap::Dict{Int, Int}, poss_swaps::Dict{Int, Set{Int}}, alpha::Float64)::Tuple{Bool, Vector{Int}}
		if isempty(poss_swaps) # Leave node, i.e., positions are fixed
			@debug "Apply swap rules: $curr_swap"
			vals = values(curr_swap)
			# Multiple vars are assigned the same position
			length(unique(vals)) != length(vals) && return false
			f2_cpy = deepcopy(f2) # Access f2 from outer scope
			perm = apply_swap_rules!(f2_cpy, curr_swap)
			return (is_swap_successful(f1, f2_cpy, alpha), perm)
		else # Not all positions have been fixed yet, so recurse further
			poss_swaps_cpy = deepcopy(poss_swaps)
			position, swaps = pop!(poss_swaps_cpy)

			for other_pos in swaps
				# Position already used
				!(other_pos in values(curr_swap)) || continue
				curr_swap[position] = other_pos
				success, perm = do_swaps!(curr_swap, poss_swaps_cpy, alpha)
				success && (return (true, perm))
				delete!(curr_swap, position)
			end

			return (false, []) # Nothing found for all possible swaps
		end
	end

	@debug "Finished computing possible swaps: $factor_set"
	success, perm = do_swaps!(Dict{Int, Int}(), factor_set, alpha)
	if success
		f2.potentials = f1.potentials
		f2.rvs = [f2.rvs[i] for i in perm]
	end
	return success
end

"""
	build_intersection!(set1::Dict{Int, Set{Int}}, set2::Dict{Int, Set{Int}})::Bool

Build the intersection of the sets in `set1` and `set2`.
Return `false` if there is an empty intersection for any of the sets, else
return `true`.
"""
function build_intersection!(set1::Dict{Int, Set{Int}}, set2::Dict{Int, Set{Int}})::Bool
	for key in keys(set1)
		set1[key] = intersect(set1[key], set2[key])
		isempty(set1[key]) && return false
	end
	return true
end

"""
	apply_swap_rules!(f::DiscreteFactor, swap_rules::Dict{Int, Int})::Vector{Int}

Apply the given swap rules to the factor `f`.
`swap_rules` is a dictionary that maps each position to a new position.
Return a vector storing the permutation of the argument positions that has been
applied.
"""
function apply_swap_rules!(f::DiscreteFactor, swap_rules::Dict{Int, Int})::Vector{Int}
	permutation = [i for i in 1:length(rvs(f))]
	for key in keys(swap_rules)
		permutation[swap_rules[key]] = key
	end
	@debug "New argument order: $permutation"
	new_potentials = Dict()
	for c in collect(Base.Iterators.product(map(x -> range(x), f.rvs)...))
		new_c = collect(c)
		new_c = [new_c[i] for i in permutation]
		new_potentials[join(new_c, ",")] = potential(f, collect(c))
	end
	f.potentials = new_potentials
	f.rvs = [f.rvs[i] for i in permutation]
	return permutation
end

"""
	is_swap_successful(f1::DiscreteFactor, f2::DiscreteFactor, alpha::Float64)::Bool

Check whether the swap of arguments in `f2` is successful, i.e., the tables of
potential mappings of `f1` and `f2` are identical up to scalar `alpha` (i.e.,
potentials of `f1` are multiplied by `alpha`).
Assumes that `f1` and `f2` are defined over the same configuration space.
"""
function is_swap_successful(f1::DiscreteFactor, f2::DiscreteFactor, alpha::Float64)::Bool
	# Assumption: map(x -> range(x), rvs(f1)) == map(x -> range(x), rvs(f2))
	k, _ = first(f1.potentials)
	max = f1.potentials[k] > f2.potentials[k] ? f1 : f2
	for c in Base.Iterators.product(map(x -> range(x), rvs(f1))...)
		conf = collect(c)
		if max == f1
			potential(f1, conf) != alpha * potential(f2, conf) && return false
		else
			alpha * potential(f1, conf) != potential(f2, conf) && return false
		end
	end
	return true
end