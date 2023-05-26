# Simple startup script

import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()


import QML 
include("src/PeaceFounderGUI.jl")

PeaceFounderGUI.load_view() do

    PeaceFounderGUI.setHome()

end
