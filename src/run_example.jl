@isdefined(FactorGraph)             || include(string(@__DIR__, "/fg/factor_graph.jl"))
@isdefined(ParfactorGraph)          || include(string(@__DIR__, "/pfg/parfactor_graph.jl"))
@isdefined(color_passing)           || include(string(@__DIR__, "/fg/color_passing.jl"))
@isdefined(advanced_color_passing!) || include(string(@__DIR__, "/fg/advanced_color_passing.jl"))
@isdefined(groups_to_pfg)           || include(string(@__DIR__, "/fg/fg_to_pfg.jl"))
@isdefined(model_to_blog)           || include(string(@__DIR__, "/pfg/blog_parser.jl"))
@isdefined(scale_factor!)           || include(string(@__DIR__, "/helper.jl"))

function run_simple_example()
	a = DiscreteRV("A")
	b = DiscreteRV("B")
	c = DiscreteRV("C")

	p = [
		([true,  true],  1.0),
		([true,  false], 2.0),
		([false, true],  3.0),
		([false, false], 4.0)
	]
	f1 = DiscreteFactor("f1", [a, b], p)
	f2 = DiscreteFactor("f2", [c, b], p)

	fg = FactorGraph()
	add_rv!(fg, a)
	add_rv!(fg, b)
	add_rv!(fg, c)
	add_factor!(fg, f1)
	add_factor!(fg, f2)
	add_edge!(fg, a, f1)
	add_edge!(fg, b, f1)
	add_edge!(fg, b, f2)
	add_edge!(fg, c, f2)

	@info "Running color_passing..."
	node_colors, factor_colors = color_passing(fg)
	pfg1, _ = groups_to_pfg(fg, node_colors, factor_colors)
	model_to_blog(pfg1)

	@info "Running advanced_color_passing!..."
	node_cols, factor_cols, commutatives, hists = advanced_color_passing!(fg, Dict{Factor, Int}(), true)
	pfg2, _ = groups_to_pfg(fg, node_cols, factor_cols, commutatives, hists)
	model_to_blog(pfg2)
end


function run_simple_example_scaled()
	a = DiscreteRV("A")
	b = DiscreteRV("B")
	c = DiscreteRV("C")

	p = [
		([true,  true],  1.0),
		([true,  false], 2.0),
		([false, true],  3.0),
		([false, false], 4.0)
	]
	f1 = DiscreteFactor("f1", [a, b], p)
	f2 = DiscreteFactor("f2", [c, b], p)
	scale_factor!(f2, 2.0)

	fg = FactorGraph()
	add_rv!(fg, a)
	add_rv!(fg, b)
	add_rv!(fg, c)
	add_factor!(fg, f1)
	add_factor!(fg, f2)
	add_edge!(fg, a, f1)
	add_edge!(fg, b, f1)
	add_edge!(fg, b, f2)
	add_edge!(fg, c, f2)

	@info "Running color_passing..."
	node_colors, factor_colors = color_passing(fg)
	pfg1, _ = groups_to_pfg(fg, node_colors, factor_colors)
	model_to_blog(pfg1)

	@info "Running advanced_color_passing!..."
	node_cols, factor_cols, commutatives, hists = advanced_color_passing!(fg, Dict{Factor, Int}(), true)
	pfg2, _ = groups_to_pfg(fg, node_cols, factor_cols, commutatives, hists)
	model_to_blog(pfg2)
end

function run_simple_crv_example()
	a = DiscreteRV("A")
	b = DiscreteRV("B")

	p = [
		([true,  true],  1),
		([true,  false], 2),
		([false, true],  2),
		([false, false], 3)
	]
	f = DiscreteFactor("f", [a, b], p)

	fg = FactorGraph()
	add_rv!(fg, a)
	add_rv!(fg, b)
	add_factor!(fg, f)
	add_edge!(fg, a, f)
	add_edge!(fg, b, f)

	@info "Running color_passing..."
	node_colors, factor_colors = color_passing(fg)
	pfg1, _ = groups_to_pfg(fg, node_colors, factor_colors)
	model_to_blog(pfg1)

	@info "Running advanced_color_passing!..."
	node_cols, factor_cols, commutatives, hists = advanced_color_passing!(fg, Dict{Factor, Int}(), true)
	pfg2, _ = groups_to_pfg(fg, node_cols, factor_cols, commutatives, hists)
	model_to_blog(pfg2)
end

function run_simple_permute_example()
	a = DiscreteRV("A")
	b = DiscreteRV("B")
	c = DiscreteRV("C")

	p1 = [
		([true,  true],  1),
		([true,  false], 2),
		([false, true],  3),
		([false, false], 4)
	]
	p2 = [
		([true,  true],  1),
		([true,  false], 3),
		([false, true],  2),
		([false, false], 4)
	]
	f1 = DiscreteFactor("f1", [a, b], p1)
	f2 = DiscreteFactor("f2", [b, c], p2)

	fg = FactorGraph()
	add_rv!(fg, a)
	add_rv!(fg, b)
	add_rv!(fg, c)
	add_factor!(fg, f1)
	add_factor!(fg, f2)
	add_edge!(fg, a, f1)
	add_edge!(fg, b, f1)
	add_edge!(fg, b, f2)
	add_edge!(fg, c, f2)

	@info "Running color_passing..."
	node_colors, factor_colors = color_passing(fg)
	pfg1, _ = groups_to_pfg(fg, node_colors, factor_colors)
	model_to_blog(pfg1)

	@info "Running advanced_color_passing!..."
	node_cols, factor_cols, commutatives, hists = advanced_color_passing!(fg, Dict{Factor, Int}(), true)
	pfg2, _ = groups_to_pfg(fg, node_cols, factor_cols, commutatives, hists)
	model_to_blog(pfg2)
end

function run_simple_combined_example()
	a = DiscreteRV("A")
	b = DiscreteRV("B")
	c = DiscreteRV("C")
	d = DiscreteRV("D")

	p1 = [
		([true,  true],  1),
		([true,  false], 2),
		([false, true],  3),
		([false, false], 4)
	]
	p2 = [
		([true,  true],  5),
		([true,  false], 6),
		([false, true],  6),
		([false, false], 7)
	]
	p3 = [
		([true,  true],  1),
		([true,  false], 3),
		([false, true],  2),
		([false, false], 4)
	]
	f1 = DiscreteFactor("f1", [a, b], p1)
	f2 = DiscreteFactor("f2", [b, c], p2)
	f3 = DiscreteFactor("f3", [c, d], p3)
	scale_factor!(f3, 2.0)

	fg = FactorGraph()
	add_rv!(fg, a)
	add_rv!(fg, b)
	add_rv!(fg, c)
	add_rv!(fg, d)
	add_factor!(fg, f1)
	add_factor!(fg, f2)
	add_factor!(fg, f3)
	add_edge!(fg, a, f1)
	add_edge!(fg, b, f1)
	add_edge!(fg, b, f2)
	add_edge!(fg, c, f2)
	add_edge!(fg, c, f3)
	add_edge!(fg, d, f3)

	@info "Running color_passing..."
	node_colors, factor_colors = color_passing(fg)
	pfg1, _ = groups_to_pfg(fg, node_colors, factor_colors)
	model_to_blog(pfg1)

	@info "Running advanced_color_passing!..."
	node_cols, factor_cols, commutatives, hists = advanced_color_passing!(fg, Dict{Factor, Int}(), true)
	pfg2, _ = groups_to_pfg(fg, node_cols, factor_cols, commutatives, hists)
	model_to_blog(pfg2)
end


if abspath(PROGRAM_FILE) == @__FILE__
	"debug" in ARGS && (ENV["JULIA_DEBUG"] = "all")

	@info "==> Running simple example..."
	run_simple_example()

	@info "==> Running simple example scaled..."
	run_simple_example_scaled()

	@info "==> Running simple crv example..."
	run_simple_crv_example()

	@info "==> Running simple permute example..."
	run_simple_permute_example()

	@info "==> Running simple combined example..."
	run_simple_combined_example()
end