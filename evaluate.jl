# Evaluate grid runs generated through bumper-continuous.jl

using Pkg; Pkg.activate(".")
using DataFrames
using CSV
using Statistics
using Printf

function stats(runs)
     @printf("adr,exit-per,exit-adr,stairs-per,stairs-adr,filename\n") 
    for filename in runs
        d = CSV.read(filename)
        total = size(d,1)
        falling = d[d[:last_reward].<=-10,:]
        exiting = d[d[:last_reward].>5,:]

        @printf("%.3f & %.1f & %.3f & %.1f & %.3f & %s\n", 
            mean(d[:discounted_reward]),
            100.0*size(exiting,1)/total, mean(exiting[:discounted_reward]),
            100.0*size(falling,1)/total, mean(falling[:discounted_reward]),
            filename
            )
    end
end

 if size(ARGS,1) > 0 
    stats(ARGS)
end
