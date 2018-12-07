# Evaluate grid runs generated through bumper-continuous.jl

using Pkg; Pkg.activate(".")
using DataFrames
using CSV
using Statistics
using Printf

runs = if size(ARGS,1) == 0 
    [
    "output/compare-15-10-4/data.txt", 
    "output/compare-15-10-4-config-2-reward-100/data.txt"
    ]
else
    ARGS
end

for filename in runs
    d = CSV.read(filename)
    total = size(d,1)
    falling = d[d[:last_reward].<=-10,:]
    exiting = d[d[:last_reward].>5,:]

    @printf("stairs %.1f %.3f, exit %.3f %f,\n", 
        100.0*size(falling,1)/total, mean(falling[:discounted_reward]),
        100.0*size(exiting,1)/total, mean(exiting[:discounted_reward])
        )
end
