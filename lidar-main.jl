using Pkg; Pkg.activate(".")

# import necessary packages
using AA228FinalProject
using POMDPs
using POMDPPolicies
using BeliefUpdaters
using ParticleFilters
using POMDPSimulators
using Random
using Printf
include("output.jl")



function init()
    sensor = Lidar() # or Bumper() for the bumper version of the environment
    config = 3 # 1,2, or 3
    pomdp = RoombaPOMDP(sensor=sensor, mdp=RoombaMDP(config=config));

    num_particles = 2000
    resampler = LidarResampler(num_particles, LowVarianceResampler(num_particles))
    # for the bumper environment
    # resampler = BumperResampler(num_particles)

    spf = SimpleParticleFilter(pomdp, resampler)

    v_noise_coefficient = 2.0
    om_noise_coefficient = 0.5

    belief_updater = RoombaParticleFilter(spf, v_noise_coefficient, om_noise_coefficient);

    return (pomdp, belief_updater)
end

pomdp, belief_updater = init()

# extract goal for heuristic controller
goal_xy = get_goal_xy(pomdp)

# define a new function that takes in the policy struct and current belief,
# and returns the desired action
function POMDPs.action(p::ToEnd, b::ParticleCollection{RoombaState})
    
    # spin around to localize for the first 25 time-steps
    if p.ts < 25
        p.ts += 1
        # get the x and y of the support, i.e. the list of roomba states
        _su = map( r -> [r[1], r[2]], support(b))
        @printf("belief mean %s variance %s \n", mean(_su), var(_su))
        return RoombaAct(0.,1.0) # all actions are of type RoombaAct(v,om)
    end
    p.ts += 1
    
    # after 25 time-steps, we follow a proportional controller to navigate
    # directly to the goal, using the mean belief state
    
    # compute mean belief of a subset of particles
    s = mean(b)
    
    # compute the difference between our current heading and one that would
    # point to the goal
    goal_x, goal_y = goal_xy
    x,y,th = s[1:3]
    ang_to_goal = atan(goal_y - y, goal_x - x)
    del_angle = wrap_to_pi(ang_to_goal - th)
    
    # apply proportional control to compute the turn-rate
    Kprop = 1.0
    om = Kprop * del_angle
    
    # always travel at some fixed velocity
    v = 5.0
    
    return RoombaAct(v, om)
end


using Statistics

function evaluate(pomdp, belief_updater)

    total_rewards = []
    runs = 50

    for exp = 1:runs
        
        Random.seed!(exp)
        
        p = ToEnd(0)
        traj_rewards = sum([step.r for step in stepthrough(pomdp,p,belief_updater, max_steps=100)])
        @printf("%d %f\n", exp, traj_rewards)
        
        push!(total_rewards, traj_rewards)
    end

    @printf("Mean Total Reward: %.3f, StdErr Total Reward: %.3f", mean(total_rewards), std(total_rewards)/sqrt(runs))
end

function run()
    init()
    # reset the policy
    p = ToEnd(0, true) # here, the argument sets the time-steps elapsed to 0
    generate_output(pomdp, p, belief_updater, "lidar")
end

@printf("\nMain exiting successfully, you may want to execute `run()`\n")