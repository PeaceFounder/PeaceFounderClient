# Simple startup script

# import Pkg
# Pkg.activate(@__DIR__)
# Pkg.instantiate()

using PeaceFounderClient


if @isdefined(Revise)

    function ReviseHandler(handle)
        return function(args...)
            Revise.revise()
            invokelatest(handle, args...)
        end
    end

    PeaceFounderClient.load_view(middleware = [ReviseHandler]) do
        PeaceFounderClient.setHome()
    end

else
    PeaceFounderClient.load_view() do
        PeaceFounderClient.setHome()
    end
end
