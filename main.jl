# Simple startup script

# import Pkg
# Pkg.activate(@__DIR__)
# Pkg.instantiate()


import QML 
include("src/PeaceFounderClient.jl")

PeaceFounderClient.load_view() do

    PeaceFounderClient.setHome()

end
