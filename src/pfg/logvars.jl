mutable struct LogVar
	name::AbstractString
	domain::Vector
	LogVar(name::AbstractString, dom::Vector) = new(name, dom)
	LogVar(name::AbstractString, d::Int) = begin
		dom = [string(lowercase(name)[1], "_", i) for i in 1:d]
		return new(name, dom)
	end
end

"""
	name(lv::LogVar)::AbstractString

Return the name of `lv`.
"""
function name(lv::LogVar)::AbstractString
	return lv.name
end

"""
	domain(lv::LogVar)::Vector

Return the domain of `lv`.
"""
function domain(lv::LogVar)::Vector
	return lv.domain
end

"""
	domain_size(lv::LogVar)::Int

Return the size of the domain of `lv`.
"""
function domain_size(lv::LogVar)::Int
	return length(lv.domain)
end

function Base.show(io::IO, lv::LogVar)
	print(io, name(lv))
end