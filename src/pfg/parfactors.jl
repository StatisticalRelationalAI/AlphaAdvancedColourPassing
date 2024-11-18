@isdefined(Constraint) || include(string(@__DIR__, "/constraints.jl"))

mutable struct Parfactor
	name::AbstractString
	prvs::Vector{PRV}
	potentials::Dict{String, AbstractFloat}
	constraint::Constraint
	Parfactor(
		name::AbstractString,
		prvs::Vector{PRV},
		ps::Array # Vector{Tuple{Vector, AbstractFloat}}
	) = new(
		name,
		prvs,
		Dict(join(tuple[1], ",") => tuple[2] for tuple in ps),
		TopConstraint()
	)
end

"""
	name(f::Parfactor)::AbstractString

Return the name of `f`.
"""
function name(f::Parfactor)::AbstractString
	return f.name
end

"""
	prvs(f::Parfactor)::Vector{PRV}

Return all PRVs contained in `f`.
"""
function prvs(f::Parfactor)::Vector{PRV}
	return f.prvs
end

"""
	logvars(f::Parfactor)::Set{LogVar}

Return all logvars occuring in `f`.
"""
function logvars(f::Parfactor)::Set{LogVar}
	return reduce(union, [logvars(prv) for prv in prvs(f)], init=Set())
end

"""
	potentials(f::Parfactor)::Array

Return the potentials of `f` (in any order).
"""
function potentials(f::Parfactor)::Array
	return [(split(c, ","), p) for (c, p) in f.potentials]
end

"""
	potentials_ordered(f::Parfactor)::Array

Return the potentials of `f` in order of descending variable assignments.
"""
function potentials_ordered(f::Parfactor)::Array
	sorted_keys = sort(collect(keys(f.potentials)), rev = true)
	return [f.potentials[key] for key in sorted_keys]
end

"""
	potential(f::Parfactor, conf::Vector)::AbstractFloat

Return the potential of the parfactor `f` for the variable assignment `conf`.
"""
function potential(f::Parfactor, conf::Vector)::AbstractFloat
	return get(f.potentials, join(conf, ","), NaN)
end

"""
	set_potentials!(f::Parfactor, ps::Array)

Set the potentials of `f` to `ps`, which is an array of tuples consisting of
a variable assignment (in form of an array) and a potential value.
For example, `ps` could be `[([true], 0.5), ([false], 0.5)]` for a parfactor
with a single PRV with domain `[true, false]`.
"""
function set_potentials!(f::Parfactor, ps::Array)
	f.potentials = Dict(join(tuple[1], ",") => tuple[2] for tuple in ps)
end

"""
	constraint(f::Parfactor)::Constraint

Return the constraint of `f`.
"""
function constraint(f::Parfactor)::Constraint
	return f.constraint
end

"""
	set_constraint!(f::Parfactor, c::Constraint)

Set the constraint of `f` to `c`.
"""
function set_constraint!(f::Parfactor, c::Constraint)
	f.constraint = c
end

function Base.deepcopy(f::Parfactor)::Parfactor
	return Parfactor(name(f), deepcopy(prvs(f)), deepcopy(potentials(f)))
end

function Base.:(==)(f1::Parfactor, f2::Parfactor)::Bool
	return f1.name == f2.name && f1.prvs == f2.prvs &&
		f1.potentials == f2.potentials
end

function Base.show(io::IO, f::Parfactor)
	print(io, name(f))
end