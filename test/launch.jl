using PeaceFounderClient

PeaceFounderClient.load_view(dir = get(ENV, "USER_DATA", "")) do
    PeaceFounderClient.setHome()
    PeaceFounderClient.closeWindow()
end
