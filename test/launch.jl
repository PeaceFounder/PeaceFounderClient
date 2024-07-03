using PeaceFounderClient

dir = joinpath(@__DIR__, "sample")

PeaceFounderClient.load_view(; dir) do
    PeaceFounderClient.setHome()
    PeaceFounderClient.setDeme(Base.UUID("033F9207-E4E4-9AAA-02EA-5DDF5E450DD8"))
    PeaceFounderClient.closeWindow()
end
