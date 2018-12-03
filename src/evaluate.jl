using AA228FinalProject: mdp, in_rectangle
using Printf
using StaticArrays: SVector

# Create a set of positions where to run the evaluation. 
function evaluation_states(pomdp::RoombaPOMDP, nx::Int, ny::Int, nth::Int)
    rects = mdp(pomdp).room.rectangles
    min_xy = minimum([[r.xl, r.yl] for r in rects])
    max_xy = maximum([[r.xu, r.yu] for r in rects])
    delta_xy = (max_xy - min_xy) 
    min_xy += 0.1 * delta_xy
    delta_xy .*= 0.9
    delta_xy ./= [nx,ny]
    delta_th= 2*pi/nth
    states = []
    for i in 0:nx
        x = min_xy[1] + delta_xy[1] * i
        for j in 0:ny
            y =  min_xy[2] + delta_xy[2] * j
            # check to see if it's in any of the rectangles
            pos = SVector(x,y)
            if isempty(Iterators.filter(r -> in_rectangle(r, pos), rects))
                continue
            end
            for k in 1:nth
                th = 0 + (k - 1) * delta_th
                s = RoombaState(x, y, th, 0.0)
                push!(states, s)
            end
        end
    end
    states

end
