# Simple startup script

import QML 
include("src/PeaceFounderGUI.jl")

PeaceFounderGUI.load_view() do

    PeaceFounderGUI.setHome()

end
