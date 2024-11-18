using Statistics

@isdefined(nanos_to_millis) || include(string(@__DIR__, "/../src/helper.jl"))

"""
	prepare_query_times_main(file::String)

Build averages over multiple runs and write the results into a new `.csv` file
that is used for plotting in the main paper.
"""
function prepare_query_times_main(file::String)
	if !isfile(file)
		@warn "File '$file' does not exist and is ignored."
		return
	end

	new_file = replace(file, ".csv" => "-prepared-main.csv")
	if isfile(new_file)
		@warn "File '$new_file' already exists and is ignored."
		return
	end

	averages = Dict()
	open(file, "r") do io
		readline(io) # Remove header
		for line in readlines(io)
			cols = split(line, ",")
			algo = match(r"-cp=([a-zA-Z]+)", cols[2])[1]
			d = parse(Int, match(r"-d1?=(\d+)-", cols[2])[1])
			time = nanos_to_millis(parse(Float64, cols[12]))
			haskey(averages, algo) || (averages[algo] = Dict())
			haskey(averages[algo], d) || (averages[algo][d] = [])
			push!(averages[algo][d], time)
		end
	end

	open(new_file, "a") do io
		write(io, "d,algo,min_t,max_t,mean_t,median_t,std\n")
		for (algo, ds) in averages
			for (d, times) in ds
				# Average with timeouts does not work
				if any(t -> isnan(t), times)
					@warn "Ignoring $algo with d=$d due to NaN values."
					continue
				end
				write(io, string(
					d, ",",
					algo, ",",
					minimum(times), ",",
					maximum(times), ",",
					mean(times), ",",
					median(times), ",",
					std(times), "\n"
				))
			end
		end
	end
end

"""
	prepare_query_times_appendix(file::String)

Build averages over multiple runs and write the results into a new `.csv` file
that is used for plotting in the appendix.
"""
function prepare_query_times_appendix(file::String)
	if !isfile(file)
		@warn "File '$file' does not exist and is ignored."
		return
	end

	new_file = replace(file, ".csv" => "-prepared-appendix.csv")
	if isfile(new_file)
		@warn "File '$new_file' already exists and is ignored."
		return
	end

	averages = Dict()
	open(file, "r") do io
		readline(io) # Remove header
		for line in readlines(io)
			cols = split(line, ",")
			algo = match(r"-cp=([a-zA-Z]+)", cols[2])[1]
			d = parse(Int, match(r"-d1?=(\d+)-", cols[2])[1])
			p = match(r"-p=(\d+)-", cols[2])[1]
			p = parse(Float64, string(p[1], ".", p[2:end]))
			time = nanos_to_millis(parse(Float64, cols[12]))
			haskey(averages, algo) || (averages[algo] = Dict())
			haskey(averages[algo], d) || (averages[algo][d] = Dict())
			haskey(averages[algo][d], p) || (averages[algo][d][p] = [])
			push!(averages[algo][d][p], time)
		end
	end

	open(new_file, "a") do io
		write(io, "d,p,algo,min_t,max_t,mean_t,median_t,std\n")
		for (algo, ds) in averages
			for (d, ps) in ds
				for (p, times) in ps
					# Average with timeouts does not work
					if any(t -> isnan(t), times)
						@warn "Ignoring $algo with d=$d due to NaN values."
						continue
					end
					write(io, string(
						d, ",",
						p, ",",
						algo, ",",
						minimum(times), ",",
						maximum(times), ",",
						mean(times), ",",
						median(times), ",",
						std(times), "\n"
					))
				end
			end
		end
	end
end

"""
	prepare_beta(file::String)

Parse the times of the BLOG inference output, build the average number of
queries needed to amortise the additional offline overhead and write the
results into a new `.csv` file.
"""
function prepare_beta(file::String)
	if !isfile(file)
		@warn "File '$file' does not exist and is ignored."
		return
	end

	new_file_1 = replace(file, ".csv" => "-offline-prepared-all.csv")
	new_file_2 = replace(file, ".csv" => "-offline-prepared-avg.csv")
	if isfile(new_file_1)
		@warn "File '$new_file_1' already exists and is ignored."
		return
	elseif isfile(new_file_2)
		@warn "File '$new_file_2' already exists and is ignored."
		return
	end

	averages = Dict()
	open(file, "r") do io
		readline(io) # Remove header
		for line in readlines(io)
			cols = split(line, ",")
			algo = match(r"-cp=([a-zA-Z]+)", cols[2])[1]
			d = parse(Int, match(r"-d1?=(\d+)-", cols[2])[1])
			p = match(r"-p=(\d+)-", cols[2])[1]
			p = parse(Float64, string(p[1], ".", p[2:end]))
			time = nanos_to_millis(parse(Float64, cols[12]))
			haskey(averages, p) || (averages[p] = Dict())
			haskey(averages[p], d) || (averages[p][d] = Dict())
			haskey(averages[p][d], algo) || (averages[p][d][algo] = [])
			push!(averages[p][d][algo], time)
		end
	end

	offline_times = Dict()
	open(replace(file, "_stats" => ""), "r") do io
		readline(io) # Remove header
		for line in readlines(io)
			cols = split(line, ",")
			algo = cols[2]
			d = parse(Int, match(r"-d1?=(\d+)-", cols[1])[1])
			p = parse(Float64, cols[4])
			cp_time = parse(Float64, cols[13])
			haskey(offline_times, p) || (offline_times[p] = Dict())
			haskey(offline_times[p], d) || (offline_times[p][d] = Dict())
			haskey(offline_times[p][d], algo) || (offline_times[p][d][algo] = [])
			push!(offline_times[p][d][algo], cp_time)
		end
	end

	open(new_file_1, "a") do io
		write(io, "d,p,gain,overhead,beta\n")
		for (p, ds) in averages
			for (d, _) in ds
				gain = averages[p][d]["ACP"] .- averages[p][d]["aACP"]
				overhead = offline_times[p][d]["aACP"] .- offline_times[p][d]["ACP"]
				betas = round.(overhead ./ gain, digits=2)
				for (index, beta) in enumerate(betas)
					write(io, string(
						d, ",",
						p, ",",
						gain[index], ",",
						overhead[index], ",",
						beta, "\n"
					))
				end
			end
		end
	end

	open(new_file_2, "a") do io
		write(io, "d,p,min_beta,max_beta,mean_beta,median_beta,std\n")
		for (p, ds) in averages
			for (d, _) in ds
				gain = averages[p][d]["ACP"] .- averages[p][d]["aACP"]
				overhead = offline_times[p][d]["aACP"] .- offline_times[p][d]["ACP"]
				betas = round.(overhead ./ gain, digits=2)
				write(io, string(
					d, ",",
					p, ",",
					minimum(betas), ",",
					maximum(betas), ",",
					mean(betas), ",",
					median(betas), ",",
					std(betas), "\n"
				))
			end
		end
	end
end


### Entry point ###
if abspath(PROGRAM_FILE) == @__FILE__
	prepare_query_times_main(string(@__DIR__, "/results_stats.csv"))
	prepare_query_times_appendix(string(@__DIR__, "/results_stats.csv"))
	prepare_beta(string(@__DIR__, "/results_stats.csv"))
end