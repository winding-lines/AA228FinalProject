# Roomba Project Update

## Code familiarity

Initially I was not able to run the code in the Lidar Roomba notebook because of issues
with GTK. This was solved once I replaced the output code to generate png files instead,
see https://gist.github.com/winding-lines/f17bcf849f370ecaf1038c8f6f7beeaa


I read all the source files and related documentation. As I was reading wikipedia I found a broken link in https://en.wikipedia.org/wiki/Particle_filter. I created a wikipedia account (Puzzled18) and I fixed the link, my first edit ever.

## Base line policy

I explored both online and offline solvers: POMCPOW, FIB, SARSOP. In spite of going back and forth between the docs, DMU book and examples I was not successful getting a policy yet.

Once I get the policy the strategy to evaluate it to use the simulate function and compare against a Random policy.

## Next steps

As my next steps I plan to get both an online and offline solvers working on
the project. Then I will focus on better understanding point-based POMDP
algorithms since I am very intrigued by their ability to find approximate
optimal behavior in high dimensional space.

I understand better by writing code and I am wondering if there is a value to re-implement SARSOP in pure Julia, as part of my exploration. I would appreciate feedback on this idea.