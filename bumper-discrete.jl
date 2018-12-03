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
using SARSOP

function init()
    sensor = Bumper() # or Lidar() for the bumper version of the environment
    config = 3 # 1,2, or 3

    # discrete state space
    num_x_pts = 20
    num_y_pts = 20
    num_th_pts = 20
    sspace = DiscreteRoombaStateSpace(num_x_pts,num_y_pts,num_th_pts)

    # discrete action space
    vlist = [0,1,2,]
    omlist = [-1, 0, 1]
    aspace = vec(collect(RoombaAct(v, om) for v in vlist, om in omlist))

    pomdp = RoombaPOMDP(sensor=sensor, mdp=RoombaMDP(config=config, sspace=sspace, aspace=aspace));

    return pomdp
end

# access the mdp of a RoombaModel
mdp(e::RoombaMDP) = e
mdp(e::RoombaPOMDP) = e.mdp

function do_solve(pomdp)
    solver = SARSOPSolver()
    solve(solver, pomdp)
    policy
end

function compare(pomdp, real_policy)
    rand_policy = RandomPolicy(pomdp);
    rollout_sim = RolloutSimulator(max_steps=1000);
    history_real = simulate(rollout_sim, pomdp, real_policy);
    history_rand = simulate(rollout_sim, pomdp, rand_policy);
    @show history_real, history_rand
end

function POMDPs.pdf(d::AA228FinalProject.RoombaInitialDistribution, s::RoombaState)
    # @printf("pdf(%s)\n", s)
    error("not implemented")
    0.0
end

function run() 
    pomdp = init()
    println("solving")
    policy = do_solve(pomdp)
    println("comparing")
    compare(pomdb, policy)
end