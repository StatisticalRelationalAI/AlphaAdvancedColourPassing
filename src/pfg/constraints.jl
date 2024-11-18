abstract type Constraint end

struct RConstraint <: Constraint
	name::AbstractString
	lvs::Vector{LogVar}
	assignments::Set{Tuple}
	RConstraint(name::AbstractString) = new(name, Vector{LogVar}(), Set{Tuple}())
end

struct TopConstraint <: Constraint
	TopConstraint() = RConstraint("T")
end

"""
	logvars(c::Constraint)

Return the logical variables in the constraint `c`.
"""
function logvars(c::Constraint)
	return c.lvs
end

"""
	add_lvs!(c::Constraint, lvs::Vector{LogVar})

Add the logical variables `lvs` to the constraint `c`.
"""
function add_lvs!(c::Constraint, lvs::Vector{LogVar})
	c.lvs = union(c.lvs, lvs)
end

"""
	add_assignment!(c::Constraint, assignment::Tuple)

Add the variable assignment `assignment` to the constraint `c`.
"""
function add_assignment!(c::Constraint, assignment::Tuple)
	@assert length(assignment) == length(c.lvs)
	@assert all([assignment[i] in domain(c.lvs[i]) for i in eachindex(c.lvs)])
	c.assignments = union(c.assignments, [assignment])
end