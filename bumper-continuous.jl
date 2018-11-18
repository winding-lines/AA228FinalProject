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

function init()
    sensor = Bumper() # or Lidar() for the bumper version of the environment
    config = 3 # 1,2, or 3


    pomdp = RoombaPOMDP(sensor=sensor, mdp=RoombaMDP(config=config));

    return pomdp
end

pomdp = init()

num_particles = 2000
# resampler = LidarResampler(num_particles, LowVarianceResampler(num_particles))
resampler = BumperResampler(num_particles)

spf = SimpleParticleFilter(pomdp, resampler)

v_noise_coefficient = 2.0
om_noise_coefficient = 0.5

belief_updater = RoombaParticleFilter(spf, v_noise_coefficient, om_noise_coefficient)


function do_solve(pomdp)
    solver = POMCPOWSolver()
    policy = solve(solver, pomdp)
    policy
end

function compare(pomdp, real_policy)
    hr = HistoryRecorder(max_steps=100)
    hist = simulate(hr, pomdp, real_policy, belief_updater)
    for (s, b, a, r, sp, o) in hist
        @show s, a, r, sp
    end
    
    rhist = simulate(hr, pomdp, RandomPolicy(pomdp))
    println("""
        Cumulative Discounted Reward (for 1 simulation)
            Random: $(discounted_reward(rhist))
            POMCPOW: $(discounted_reward(hist))
        """)
end

function run() 
    pomdp = init()
    println("solving")
    policy = do_solve(pomdp)
    println("comparing")
    compare(pomdp, policy)
end