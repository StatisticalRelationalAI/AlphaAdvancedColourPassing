# Alpha-Advanced Colour Passing

This repository contains the source code of the alpha-advanced colour passing
algorithm that has been presented in the paper
"Lifted Model Construction without Normalisation: A Vectorised Approach to
Exploit Symmetries in Factor Graphs" by Malte Luttermann, Ralf Möller, and
Marcel Gehrke (LoG 2024).

Our implementation uses the [Julia programming language](https://julialang.org).

## Computing Infrastructure and Required Software Packages

All experiments were conducted using Julia version 1.8.1 together with the
following packages:
- BenchmarkTools v1.3.1
- Combinatorics v1.0.2
- Multisets v0.4.4
- OrderedCollections v1.6.3
- StatsBase v0.33.21

Moreover, we use openjdk version 11.0.20 to run the (lifted) inference
algorithms, which are integrated via
`instances/ljt-v1.0-jar-with-dependencies.jar`.

## Instance Generation

First, the input instances must be generated.
To do so, run `julia instance_generator.jl all` in the `src/` directory.
The input instances are then written to `instances/input`.

## Running the Experiments

After the instances have been generated, the experiments can be started by
running `julia run_eval.jl all` in the `src/` directory.
The (lifted) inference algorithms are then directly executed by the Julia
script.
All results are written into the `results/` directory.

To create the plots, run `julia prepare_plot.jl` in the `results/` directory
to combine the obtained run times into averages and afterwards execute the R
script `plot.r` (also in the `results/` directory).
The R script will then create a bunch of `.pdf` files in the `results/`
directory containing the plots of the experiments.
To generate the plots as `.pdf` files instead, set `use_tikz = FALSE` in
line 7 of `plot.r` before executing the R script `plot.r`.