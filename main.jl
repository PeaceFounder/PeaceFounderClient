# Simple startup script

# import Pkg
# Pkg.activate(@__DIR__)
# Pkg.instantiate()

# LOGFILE_PATH = joinpath(ENV["USER_DATA"], "session.log")
# rm(LOGFILE_PATH, force=true)
# logfile = open(LOGFILE_PATH, "w")
# redirect_stdout(logfile)
# redirect_stderr(logfile)

using PeaceFounderClient

if @isdefined(Revise)

    function ReviseHandler(handle)
        return function(args...)
            Revise.revise()
            invokelatest(handle, args...)
        end
    end

    PeaceFounderClient.load_view(middleware = [ReviseHandler], dir = get(ENV, "USER_DATA", "")) do
        PeaceFounderClient.setHome()
    end

else
    PeaceFounderClient.load_view(dir = get(ENV, "USER_DATA", ""), qmldir = joinpath(@__DIR__, "qml")) do
        PeaceFounderClient.setHome()
    end
end


function ReviseHandler(handle)
    return function(args...)
        Revise.revise()
        invokelatest(handle, args...)
    end
end
