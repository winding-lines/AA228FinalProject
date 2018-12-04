# AA228FinalProject
Codebase for the optional final project of AA228 Autumn 2018.

An example video showing the robot first localizing itself using its bump sensors, then navigating safely to the goal. The Roomba's belief about where it may be located is represented by the blue regions, and is updated using a particle filter.
<img src="demo.gif" width="450">

## Installation
Clone this repository using
```
git clone https://github.com/winding-lines/AA228FinalProject
```
and `cd` into it.

Then, run the following commands in Julia:
```julia
import POMDPs
POMDPs.add_registry()
```

Enter the package manager by hitting the ```]``` key. Then activate the AA228FinalProject environment with the command:
```
activate .
```
Once activated, your prompt should become:
```
(AA228FinalProject) pkg> 
```
Now run the following command to install all the necessary dependencies:
```
instantiate
```
Note: if you're running Windows and have trouble building the POMDPSolve and SARSOP dependencies, don't worry. It shouldn't interfere with you being able to get started. We're looking into whether the build issues can be resolved. 


## Run the evaluation code

In the julia shell run 

```
include("bumper-continuous.jl")
main(1,0)
```

This will re-generate the output/compare-15-10-4 folder.