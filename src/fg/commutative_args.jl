@isdefined(buckets_ordered) || include(string(@__DIR__, "/buckets.jl"))

"""
	commutative_args_decor(f::DiscreteFactor, hist_cache::Dict{Factor, Tuple{OrderedDict, Dict}})::Vector{DiscreteRV}

Return a maximal subset of `f`'s arguments such that `f` is commutative
with respect to that subset.
If no subset with size at least two exists, return an empty set.
The implementation uses buckets to heavily prune the search space.

## References
M. Luttermann, J. Machemer, and M. Gehrke.
Efficient Detection of Commutative Factors in Factor Graphs.
PGM, 2024.
"""
function commutative_args_decor(f::DiscreteFactor, hist_cache::Dict{Factor, Tuple{OrderedDict, Dict}})::Vector{DiscreteRV}
	!haskey(hist_cache, f) && (hist_cache[f] = buckets_ordered(f, false))

	buckets_f, confs_f = hist_cache[f]
	candidates_list = [rvs(f)]

	for (bucket_key, bucket_values) in buckets_f
		# Skip if bucket contains only one item
		length(bucket_values) == 1 && continue

		groups = get_groups_from_bucket(bucket_values, confs_f[bucket_key])
		isempty(groups) && return Vector{DiscreteRV}()

		# Compute candidates for every group inside of the current bucket
		bucket_candidates_list = Vector{Vector{DiscreteRV}}()
		for (group_key, group_values) in groups
			group_candidates = compute_candidates(group_values, rvs(f))
			push!(bucket_candidates_list, group_candidates)
		end

		# Intersect each set of bucket candidates with each set of previous
		# candidates
		new_candidates_list = Vector{Vector{DiscreteRV}}()
		for last_candidates in candidates_list
			for bucket_candidates in bucket_candidates_list
				sect = intersect(last_candidates, bucket_candidates)
				if length(sect) > 1 && !in(sect, new_candidates_list)
					push!(new_candidates_list, sect)
				end
			end
		end

		# If no candidates are left, stop
		isempty(new_candidates_list) && return Vector{DiscreteRV}()
		# Update candidate list
		candidates_list = new_candidates_list
	end

	# Return the largest candidate set
	return argmax(length, candidates_list)
end

"""
	get_groups_from_bucket(bucket_values::Vector, bucket_confs::Vector)::Dict

	Returns the groups inside of a bucket with size larger than 1.
"""
function get_groups_from_bucket(bucket_values::Vector, bucket_confs::Vector)::Dict
	groups = Dict()

	for (index, item) in enumerate(bucket_values)
		if !haskey(groups, item)
			cnt = count(x -> x == item, bucket_values)
			cnt < 2 && continue
			groups[item] = []
			push!(groups[item], bucket_confs[index])
		else
			push!(groups[item], bucket_confs[index])
		end
	end

	return groups
end

"""
	compute_candidates(group::Vector, rv_f::Vector)::Vector{DiscreteRV}

Returns the candidates for the given group.
"""
function compute_candidates(group::Vector, rv_f::Vector)::Vector{DiscreteRV}
	candidates = Vector{DiscreteRV}()

	for (index, rv) in enumerate(rv_f)
		isallequal = true
		last = group[1][index]
		for i in 2:length(group)
			group[i][index] != last && (isallequal = false)
			last = group[i][index]
		end

		!isallequal && push!(candidates, rv)
	end

	return candidates
end