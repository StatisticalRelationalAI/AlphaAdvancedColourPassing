using Dates, Random

@isdefined(FactorGraph)  || include(string(@__DIR__, "/fg/factor_graph.jl"))
@isdefined(gen_randpots) || include(string(@__DIR__, "/helper.jl"))
@isdefined(Query)        || include(string(@__DIR__, "/queries.jl"))

"""
	run_generation(output_dir=string(@__DIR__, "/../instances/input/"), seed=123)

Run the instance generation procedure to generate the instances.
"""
function run_generation(
	output_dir=string(@__DIR__, "/../instances/input/"),
	seed=123
)
	Random.seed!(seed)

	dom_sizes = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024]
	probabilities = [0.01, 0.05, 0.1, 0.15]

	for p in probabilities
		p_str = replace(string(p), "." => "")

		# Epid model
		for d1 in dom_sizes
			d2 = round(Int, log2(d1))
			d1_str = lpad(d1, 4, "0")
			d2_str = lpad(d2, 2, "0")
			@info "Generating epid model with d1=$d1, d2=$d2, and p=$p..."
			fg, queries = gen_epid(d1, d2, p, seed)
			save_to_file(
				(fg, queries),
				string(output_dir, "epid-d1=$d1_str-d2=$d2_str-p=$p_str.ser")
			)
		end

		# Double shared model
		for d in dom_sizes
			d_str = lpad(d, 2, "0")
			for n in [4, 6]
				n_str = lpad(n, 2, "0")
				@info "Generating double_shared_pf model with d=$d, n=$n, and p=$p..."
				fg, queries = gen_double_shared_pf(n, d, p, seed)
				save_to_file(
					(fg, queries),
					string(output_dir, "ds-d=$d_str-n=$n_str-p=$p_str.ser")
				)
			end
		end

		# Employee model
		for d in dom_sizes
			d_str = lpad(d, 2, "0")
			@info "Generating employee model with d=$d and p=$p..."
			fg, queries = gen_employee(d, p, seed)
			save_to_file(
				(fg, queries),
				string(output_dir, "employee-d=$d_str-p=$p_str.ser")
			)
		end
	end
end

"""
	gen_employee(dom_size::Int, p::Float64, seed::Int=123)::Tuple{FactorGraph, Vector{Query}}

Generate the employee example with the given domain size for employees.
With probability `p`, potentials are scaled by a randomly chosen scalar.
"""
function gen_employee(
	dom_size::Int,
	p::Float64,
	seed::Int=123
)::Tuple{FactorGraph, Vector{Query}}
	@assert dom_size > 0

	Random.seed!(seed)
	fg = FactorGraph()

	rev = DiscreteRV("Rev")
	add_rv!(fg, rev)

	r = [true, false] # All random variables are Boolean
	p1 = [([true], 1), ([false], 1)]
	p2 = gen_randpots([r, r], 1)
	p3 = gen_randpots([r, r, r], 2)
	for i in 1:dom_size
		com = DiscreteRV("Com.$i")
		sal = DiscreteRV("Sal.$i")
		add_rv!(fg, com)
		add_rv!(fg, sal)

		f_com = DiscreteFactor("f_com$i", [com], p1)
		rand() < p && scale_factor!(f_com, rand(1.0:1.0:10.0))
		add_factor!(fg, f_com)
		add_edge!(fg, com, f_com)

		f_rev = DiscreteFactor("f_rev$i", [com, rev], p2)
		rand() < p && scale_factor!(f_rev, rand(1.0:1.0:10.0))
		add_factor!(fg, f_rev)
		add_edge!(fg, com, f_rev)
		add_edge!(fg, rev, f_rev)

		f_sal = DiscreteFactor("f_sal$i", [com, rev, sal], p3)
		rand() < p && scale_factor!(f_sal, rand(1.0:1.0:10.0))
		add_factor!(fg, f_sal)
		add_edge!(fg, com, f_sal)
		add_edge!(fg, rev, f_sal)
		add_edge!(fg, sal, f_sal)
	end

	queries = [Query("Rev"), Query("Com.1"), Query("Sal.1")]

	return fg, queries
end

"""
	gen_epid(d1::Int, d2::Int, p::Float64, seed::Int=123)::Tuple{FactorGraph, Vector{Query}}

Generate the epid example with the given domain sizes for people (`d1`) and
medications (`d2`).
With probability `p`, potentials are scaled by a randomly chosen scalar.
"""
function gen_epid(
	d1::Int,
	d2::Int,
	p::Float64,
	seed::Int=123
)::Tuple{FactorGraph, Vector{Query}}
	@assert d1 > 0 && d2 > 0

	Random.seed!(seed)
	fg = FactorGraph()

	r = [true, false] # All random variables are Boolean
	p0 = [([true], 1), ([false], 1)]
	p1 = gen_randpots([r, r, r], 1)
	p2 = gen_randpots([r, r, r], 2)

	epid = DiscreteRV("Epid")
	f0 = DiscreteFactor("f0", [epid], p0)
	add_rv!(fg, epid)
	add_factor!(fg, f0)
	add_edge!(fg, epid, f0)

	for i in 1:d1
		travel = DiscreteRV("Travel.$i")
		sick = DiscreteRV("Sick.$i")
		add_rv!(fg, travel)
		add_rv!(fg, sick)
		f1 = DiscreteFactor("f1_$i", [travel, sick, epid], p1)
		rand() < p && scale_factor!(f1, rand(1.0:1.0:10.0))
		add_factor!(fg, f1)
		add_edge!(fg, travel, f1)
		add_edge!(fg, sick, f1)
		add_edge!(fg, epid, f1)
		for j in 1:d2
			treat = DiscreteRV("Treat.$i-$j")
			add_rv!(fg, treat)
			f2 = DiscreteFactor("f2_$i-$j", [sick, epid, treat], p2)
			rand() < p && scale_factor!(f2, rand(1.0:1.0:10.0))
			add_factor!(fg, f2)
			add_edge!(fg, sick, f2)
			add_edge!(fg, epid, f2)
			add_edge!(fg, treat, f2)
		end
	end

	queries = [Query("Epid"), Query("Travel.1"), Query("Sick.1"), Query("Treat.1-1")]

	return fg, queries
end

"""
	gen_double_shared_pf(
		num_prvs::Int,
		dom_size::Int,
		p::Float64,
		seed::Int=123
	)::Tuple{FactorGraph, Vector{Query}}

Generate a factor graph stemming from grounding a parfactor graph with two
parfactors, one connecting a parameterless PRV with a PRV R having a logvar X
with domain size `dom_size`, and the other parfactor connecting R as well as
`num_prvs` additional PRVs with the same logvar X.
With probability `p`, potentials are scaled by a randomly chosen scalar.
"""
function gen_double_shared_pf(
	num_prvs::Int,
	dom_size::Int,
	p::Float64,
	seed::Int=123
)::Tuple{FactorGraph, Vector{Query}}
	@assert num_prvs > 0 && dom_size > 0

	Random.seed!(seed)
	fg = FactorGraph()

	r = [true, false] # All random variables are Boolean
	p0 = gen_randpots(fill(r, 2))
	p1 = gen_randpots(fill(r, num_prvs + 1))

	rv0 = DiscreteRV("R0")
	add_rv!(fg, rv0)
	for d in 1:dom_size
		rv1 = DiscreteRV("R1_$d")
		add_rv!(fg, rv1)
		f1 = DiscreteFactor("f1_$d", [rv0, rv1], p0)
		rand() < p && scale_factor!(f1, rand(1.0:1.0:10.0))
		add_factor!(fg, f1)
		add_edge!(fg, rv0, f1)
		add_edge!(fg, rv1, f1)
		other_rvs = []
		for i in 1:num_prvs
			rv = DiscreteRV("R$(i+1)_$d")
			add_rv!(fg, rv)
			push!(other_rvs, rv)
		end
		f2 = DiscreteFactor("f2_$d", [rv1, other_rvs...], p1)
		rand() < p && scale_factor!(f2, rand(1.0:1.0:10.0))
		add_factor!(fg, f2)
		add_edge!(fg, rv1, f2)
		for rv in other_rvs
			add_edge!(fg, rv, f2)
		end
	end

	queries = [Query("R0"), Query("R1_1"), Query("R2_1")]

	return fg, queries
end


### Entry point ###
if abspath(PROGRAM_FILE) == @__FILE__
	start = Dates.now()

	run_generation()

	@info "=> Start:      $start"
	@info "=> End:        $(Dates.now())"
	@info "=> Total time: $(Dates.now() - start)"
end