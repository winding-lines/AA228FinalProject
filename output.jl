using AA228FinalProject
using POMDPs
using POMDPPolicies
using BeliefUpdaters
using ParticleFilters
using POMDPSimulators
using Random
using Printf
using Cairo


# Define the policy to test
mutable struct ToEnd <: Policy
    ts::Int64 # to track the current time-step.
    searching::Bool
end


function generate_output(pomdp, p, belief_updater, folder)
    @printf("Entering\n")
    Random.seed!(2)

    # run the simulation

    #=
    c = @GtkCanvas()
    win = GtkWindow(c, "Roomba Environment", 600, 600)
    =#

    c = CairoRGBSurface(700, 500);
    cr = CairoContext(c);
    animated_gif = "output/$folder.gif"

    rm("output/$folder"; force = true, recursive=true)
    rm(animated_gif; force=true)
    mkdir("output/$folder")
    args = ["-loop", "0", "-delay", "10"]

    for (t, step) in enumerate(stepthrough(pomdp, p, belief_updater, max_steps=500))
        # @printf("timestep %d\n", t)
        # the following lines render the room, the particles, and the roomba
        set_source_rgb(cr,1,1,1)
        paint(cr)
        render(cr, pomdp, step)

        # render some information that can help with debugging
        # here, we render the time-step, the state, and the observation
        move_to(cr,300,400)
        show_text(cr, @sprintf("t=%d, state=%s",t, string(step.s) ))
        name = @sprintf("output/%s/out-%03d.png", folder, t)
        push!(args, name)
        if t % 50 == 0
            @printf(" %d ", t)
        end
        write_to_png(c,name);
    end
    println("assembling output gif")
    push!(args, animated_gif)
    Base.run(`convert $args`)
    animated_gif
end

# Render a line through the run
function render_history(name::String, room, hist::POMDPHistory)
    full_name = "output/$name.png"
    rm(full_name; force = true)

    c = CairoRGBSurface(700, 500);
    cr = CairoContext(c);
    set_source_rgb(cr,1,1,1)
    paint(cr)

    AA228FinalProject.render(room, cr)
    path_len = length(hist)
    last_reward = reward_hist(hist)[path_len]
    final_color = if last_reward < -5 ; [1,0,0.1] elseif last_reward > 5 ; [0,1,0.1] else [0.1, 0.1, 0.1] end
    for (i,(s, b, a, r, sp, o)) in enumerate(hist)
        pos = i/path_len
        x, y = AA228FinalProject.transform_coords(s[1:2])
        arc(cr, x, y, 2, 0, 2*pi)
        color = [0,0,1] .* (1-pos) + final_color .* pos
        set_source_rgba(cr, color..., 0.4)
        fill(cr)
    end

    write_to_png(c, full_name)
    return (last_reward, path_len)
end