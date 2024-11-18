@isdefined(LogVar) || include(string(@__DIR__, "/logvars.jl"))

mutable struct PRV
	name::AbstractString
	range::Vector
	logvars::Vector{LogVar}
	counted_over::Union{LogVar, Nothing}
	counted_in::Vector
	PRV(name::AbstractString, range::Vector) =
		new(name, range, [], nothing, [])
	PRV(name::AbstractString, range::Vector, lvs::Vector) =
		new(name, range, lvs, nothing, [])
	PRV(name::AbstractString, range::Vector, lvs::Vector,
		counted_over::Union{LogVar, Nothing}, counted_in::Vector
	) =
		new(name, range, lvs, counted_over, counted_in)
end

"""
	name(prv::PRV)::AbstractString

Return the name of `prv`.
"""
function name(prv::PRV)::AbstractString
	return prv.name
end

"""
	range(prv::PRV)::Vector

Return the range of `prv`.
"""
function range(prv::PRV)::Vector
	return prv.range
end

"""
	logvars(prv::PRV)::Vector{LogVar}

Return all logvars of `prv`.
"""
function logvars(prv::PRV)::Vector{LogVar}
	return prv.logvars
end

"""
	counted_over(prv::PRV)::Union{LogVar, Nothing}

Return the logvar that `prv` is counted over, or `nothing` if it is not
counted over any logvar.
"""
function counted_over(prv::PRV)::Union{LogVar, Nothing}
	return prv.counted_over
end

"""
	counted_in(prv::PRV)::Vector

Return the parfactors in which `prv` appears count converted.
"""
function counted_in(prv::PRV)::Vector
	return prv.counted_in
end

"""
	is_crv(prv::PRV)::Bool

Return `true` if the given parameterized random variable `prv` is a
counting random variable, and `false` otherwise.
"""
function is_crv(prv::PRV)::Bool
	return !isnothing(prv.counted_over)
end

function Base.deepcopy(prv::PRV)::PRV
	return PRV(
		name(prv),
		deepcopy(range(prv)),
		deepcopy(logvars(prv)),
		deepcopy(counted_over(prv)),
		deepcopy(counted_in(prv))
	)
end

function Base.:(==)(prv1::PRV, prv2::PRV)::Bool
	return prv1.name == prv2.name &&
		prv1.range == prv2.range &&
		prv1.logvars == prv2.logvars &&
		prv1.counted_over == prv2.counted_over
		# No counted_in comparison due to circular references
end

function Base.show(io::IO, prv::PRV)
	if isempty(logvars(prv)) # Propositional random variable
		print(io, name(prv))
	else
		print(io, string(name(prv), "(", join(logvars(prv), ","), ")"))
	end
end