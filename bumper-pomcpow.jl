using Pkg; Pkg.activate(".")

# import necessary packages
using AA228FinalProject
using POMDPs
using POMCPOW
using POMDPPolicies
using BeliefUpdaters
using ParticleFilters
using POMDPSimulators
using Random
using Printf

include("output.jl")
include("src/evaluate.jl")

function init(room_config, reward)
    sensor = Bumper() 


    mdp = RoombaMDP(config=room_config)
    mdp.goal_reward = reward
    pomdp = RoombaPOMDP(sensor=sensor, mdp=mdp);

    return pomdp
end

function init_belief_updater(pomdp)
    num_particles = 2000
    # resampler = LidarResampler(num_particles, LowVarianceResampler(num_particles))
    resampler = BumperResampler(num_particles)

    spf = SimpleParticleFilter(pomdp, resampler)

    v_noise_coefficient = 2.0
    om_noise_coefficient = 0.5

    RoombaParticleFilter(spf, v_noise_coefficient, om_noise_coefficient)

end

Base.rand(::MersenneTwister, a::AA228FinalProject.RoombaActions) = begin 
    AA228FinalProject.RoombaAct(rand(Float64)*2, rand(Float64)*2-1)
end

function do_solve(pomdp)
    solver = POMCPOWSolver(;criterion=MaxUCB(20.0), max_depth=20)
    policy = solve(solver, pomdp)
    policy
end

function compare(label::String, pomdp::RoombaPOMDP, real_policy, skip::Int)
    nx = 15
    ny = 10
    nth = 4
    states = evaluation_states(pomdp, nx, ny, nth)
    folder = "compare-$(nx)-$(ny)-$(nth)-$(label)"
    # rm("output/$(folder)"; force = true, recursive = true)
    if !isdir("output/$(folder)")
        mkdir("output/$(folder)")
    end
    full_label = "$(folder)/out"
    room = mdp(pomdp).room

    #random_hr = HistoryRecorder(max_steps=600)
    #rhist = simulate(random_hr, pomdp, RandomPolicy(pomdp))
    #render_history("$(label)-random", room, rhist)
    
    #println("Random, $(discounted_reward(rhist))")

    # compute the history for all the states
    for (i,is) in enumerate(states)
        if i<=skip
            continue
        end
        belief_updater = init_belief_updater(pomdp)
        hr = HistoryRecorder(max_steps=400)
        dist = initialstate_distribution(pomdp)
        ib = initialize_belief(belief_updater, dist)
        try
            hist = simulate(hr, pomdp, real_policy, belief_updater, ib, is)
        
            (last_reward, path_len) = render_history("$(full_label)-$(i)", room, hist)
            data_file = "output/$(folder)/data.txt"
            if !isfile(data_file) 
                open(data_file, "a") do f
                    write(f, "index,x,y,theta,discounted_reward,last_reward,path_len\n")
                end
            end
            data = @sprintf("%d,%.3f, %.3f, %.3f, %.3f, %3f, %d\n", i,is.x, is.y, is.theta, discounted_reward(hist), last_reward, path_len)
            open(data_file, "a") do f
                write(f,data)
            end
            print(data)
        catch y
            if isa(y, InterruptException)
                return
            end
            @show i, is, y
        end
    end
    
end

function main(room_config, skip) 
    reward = 100
    pomdp = init(room_config,reward)
    println("solving")
    policy = do_solve(pomdp)
    compare("config-$(room_config)-reward-$(reward)", pomdp, policy, skip)
    println("not generating output, uncomment following line if interested")
    # generate_output(pomdp, policy, belief_updater, @sprintf("pomcpow-%d", room_config))
end