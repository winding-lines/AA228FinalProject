using Pkg; Pkg.activate(".")

# import necessary packages
using AA228FinalProject
using POMDPs
using POMDPPolicies
using BeliefUpdaters
using ParticleFilters
using POMDPSimulators
using Cairo
using Random
using Printf

# Define the policy to test
mutable struct ToEnd <: Policy
    ts::Int64 # to track the current time-step.
    searching::Bool
end


function init()
    sensor = Bumper() # or Lidar() for the bumper version of the environment
    config = 3 # 1,2, or 3
    pomdp = RoombaPOMDP(sensor=sensor, mdp=RoombaMDP(config=config));

    num_particles = 2000
    # resampler = LidarResampler(num_particles, LowVarianceResampler(num_particles))
    resampler = BumperResampler(num_particles)

    spf = SimpleParticleFilter(pomdp, resampler)

    v_noise_coefficient = 2.0
    om_noise_coefficient = 0.5

    belief_updater = RoombaParticleFilter(spf, v_noise_coefficient, om_noise_coefficient);

    return (pomdp, belief_updater)
end

pomdp, belief_updater = init()

# extract goal for heuristic controller
goal_xy = get_goal_xy(pomdp)
get_stairs(pomdp)

# define a new function that takes in the policy struct and current belief,
# and returns the desired action
function POMDPs.action(p::ToEnd, b::ParticleCollection{RoombaState})
    p.ts += 1
    
    # get the x and y of the support, i.e. the list of roomba states
    _su = map( r -> [r[1], r[2]], support(b))
    # variance
    _vsu = var(_su)
    # move in different directions until we get a lock on the position
    ok_precision = abs(_vsu[2]) < 25
    if ok_precision
        if p.searching
            println("Stopping the search")
        end
        p.searching = false
    end
    if p.searching
        @printf("%d  %s\n", p.ts, _vsu)
        if p.ts < 3
            return RoombaAct(3, -1)
        elseif p.ts < 6 
            return RoombaAct(15.0, 0) # all actions are of type RoombaAct(v,om)
        elseif p.ts == 6 || p.ts == 7 || p.ts == 8
            return RoombaAct(1, -0.6)
        elseif p.ts < 100 
            vel = if p.ts % 20 == 4 || p.ts % 20 == 5 ; 0.7 elseif p.ts % 20 == 18 || p.ts % 20 == 19; -1.0 else 0 end
            return RoombaAct(3.0, vel)
        end
    end
    
    # after the initial discovery we follow a proportional controller to navigate
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

function generate_output(pomdp, belief_updater)
    @printf("Entering\n")
    Random.seed!(2)

    # reset the policy
    p = ToEnd(0, true) # here, the argument sets the time-steps elapsed to 0

    # run the simulation

    #=
    c = @GtkCanvas()
    win = GtkWindow(c, "Roomba Environment", 600, 600)
    =#

    c = CairoRGBSurface(700, 500);
    cr = CairoContext(c);

    rm("output/bumper"; force = true, recursive=true)
    rm("out.gif"; force=true)
    mkdir("output/bumper")
    args = ["-loop", "0", "-delay", "10"]

    for (t, step) in enumerate(stepthrough(pomdp, p, belief_updater, max_steps=400))
        # @printf("timestep %d\n", t)
        # the following lines render the room, the particles, and the roomba
        set_source_rgb(cr,1,1,1)
        paint(cr)
        render(cr, pomdp, step)

        # render some information that can help with debugging
        # here, we render the time-step, the state, and the observation
        move_to(cr,300,400)
        show_text(cr, @sprintf("t=%d, state=%s",t, string(step.s) ))
        name = @sprintf("output/bumper/out-%03d.png", t)
        push!(args, name)
        if t % 50 == 0
            @printf(" %d ", t)
        end
        write_to_png(c,name);
    end
    println("assembling output gif")
    push!(args, "out.gif")
    Base.run(`convert $args`)
    "out.gif"
end

using Statistics

function evaluate(pomdp, belief_updater)

    total_rewards = []
    runs = 50

    for exp = 1:runs
        
        Random.seed!(exp)
        
        p = ToEnd(0, true)
        traj_rewards = sum([step.r for step in stepthrough(pomdp,p,belief_updater, max_steps=100)])
        @printf("%d %f\n", exp, traj_rewards)
        
        push!(total_rewards, traj_rewards)
    end

    @printf("Mean Total Reward: %.3f, StdErr Total Reward: %.3f", mean(total_rewards), std(total_rewards)/sqrt(runs))
end

function run()
    init()
    generate_output(pomdp, belief_updater)
end

@printf("\nMain exiting successfully, you may want to execute `run()`\n")