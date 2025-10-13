module PeaceFounderClient

using Dates: Dates, DateTime, TimePeriod
using PeaceFounder: Client
using PeaceFounder.Core: Model, Parser
using QML

using Qt65Compat_jll
QML.loadqmljll(Qt65Compat_jll)

using Base: UUID
using .Client: DemeClient, DemeAccount, ProposalInstance
using .Model: Selection, Proposal

using PrecompileTools
using RelocatableFolders

#const QMLDIR = @path joinpath(dirname(@__DIR__), "qml")

include("utils.jl")
include("model.jl")

global CLIENT::DemeClient

global USER_DEMES::JuliaItemModel
global DEME_STATUS::JuliaPropertyMap 
global DEME_PROPOSALS::JuliaItemModel 
global PROPOSAL_METADATA::JuliaPropertyMap
global PROPOSAL_STATUS::JuliaPropertyMap
global PROPOSAL_BALLOT::JuliaItemModel
global GUARD_STATUS::JuliaPropertyMap
global ERROR_STATUS::JuliaPropertyMap

function __init__()

    #global CLIENT = DemeClient(dir = USER_DATA)

    global USER_DEMES = JuliaItemModel(DemeItem[])

    global DEME_STATUS = JuliaPropertyMap(
        "uuid" => "UNDEFINED",
        "title" => "Local democratic community",
        "demeSpec" => "2AAE6C35 C94FCFB4 15DBE95F 408B9CE9 1EE846ED",
        "memberIndex" => 0,
        "commitIndex" => 0,
        "memberCount" => 0
    )

    global DEME_PROPOSALS = JuliaItemModel(ProposalItem[])

    global PROPOSAL_METADATA = JuliaPropertyMap(
        "index" => 0,
        "title" => "PROPOSAL TITLE",
        "description" => "PROPOSAL DESCRIPTION",
        "stateAnchor" => 0,
        "voterCount" => 0
    )

    global PROPOSAL_STATUS = JuliaPropertyMap(
        "isVotable" => false,
        "isCast" => false,
        "isTallied" => false,
        "timeWindowShort" => "HOURS Remaining",
        "timeWindowLong" => "HOURS remaining to cast your choice",
        "castCount" => 0
    )

    global PROPOSAL_BALLOT = JuliaItemModel(BallotQuestion[])

    global GUARD_STATUS = JuliaPropertyMap(
        "pseudonym" => "#223.324",
        "timestamp" => "June 15, 2009 1:45 PM",
        "castIndex" => 0,
        "commitIndex" => 0,
        "commitRoot" => "2AAE6C35 C94FCFB4 15DBE95F 408B9CE9 1EE846ED"
    )

    return
end

setHome() = reset!(USER_DEMES, DemeItem[item(i) for i in CLIENT.accounts])

function setDeme(uuid::QString, memberIndex::Integer)

    (; commit, proposals, deme, guard) = select(uuid, memberIndex, CLIENT)

    reset!(DEME_PROPOSALS, ProposalItem[item(instance) for instance in proposals])
    
    DEME_STATUS["uuid"] = QString(uppercase(string(deme.uuid)))
    DEME_STATUS["title"] = deme.title

    DEME_STATUS["memberCount"] = commit.state.member_count

    DEME_STATUS["memberIndex"] = guard.ack.proof.index
    DEME_STATUS["commitIndex"] = commit.state.index

    DEME_STATUS["demeSpec"] = Model.digest(deme, Model.hasher(deme)) |> digest_pretty_string
    
    return
end

setDeme(uuid::UUID, memberIndex::Integer) = setDeme(QString(string(uuid)), memberIndex)


function setProposal(index::Int32)

    account = select(DEME_STATUS["uuid"], DEME_STATUS["memberIndex"], CLIENT)
    instance = select(index, account)

    PROPOSAL_METADATA["index"] = instance.index
    PROPOSAL_METADATA["title"] = instance.proposal.summary |> copy
    PROPOSAL_METADATA["voterCount"] = instance.proposal.anchor.member_count
    PROPOSAL_METADATA["description"] = instance.proposal.description |> copy
    PROPOSAL_METADATA["stateAnchor"] = instance.proposal.anchor.index

    member_index = account.guard.ack.proof.index

    PROPOSAL_STATUS["isVotable"] = Client.isopen(instance) && member_index < instance.index
    PROPOSAL_STATUS["isCast"] = !isnothing(instance.guard)
    PROPOSAL_STATUS["isTallied"] = Client.istallied(instance)

    PROPOSAL_STATUS["timeWindowShort"] = time_window(instance.proposal)


    tail_str = Client.isopen(instance) && member_index < instance.index ? " to cast your vote" : ""
    PROPOSAL_STATUS["timeWindowLong"] = time_window(instance.proposal) * tail_str

    # make a recent commit method for the instance
    PROPOSAL_STATUS["castCount"] = isnothing(Model.commit(instance)) ? 0 : Model.commit(instance).state.index

    question = "" # Having it empty seems like a possibility
    options = instance.proposal.ballot.options |> copy
    
    pushfirst!(options, "Not Selected")
    choice = 0 

    ballot_question = BallotQuestion(question, options, choice)
    
    reset!(PROPOSAL_BALLOT, BallotQuestion[ballot_question])

    # I the vote is already cast
    !isnothing(instance.guard) && setGuard()

    return
end

setProposal(index::Integer) = setProposal(Int32(index))

function setGuard()

    account = select(DEME_STATUS["uuid"], DEME_STATUS["memberIndex"], CLIENT)
    instance = select(PROPOSAL_METADATA["index"], account)

    anchor_index = instance.proposal.anchor.index
    alias = instance.guard.ack_cast.alias

    #tracking_code = join(group_slice(Model.tracking_code(instance.guard, account.deme) |> bytes2hex |> uppercase, 4), '-')
    #tracking_code = join(group_slice(ProtocolSchema.tracking_code(instance.guard, account.deme) |> encode_crockford_base32, 4), '-')

    tracking_code = join(group_slice(Client.tracking_code(instance.guard, account.deme), 4), '-')

    GUARD_STATUS["pseudonym"] = "#$anchor_index.$alias"
    GUARD_STATUS["timestamp"] = timestamp = Dates.format(instance.guard.ack_cast.receipt.timestamp |> local_time, "d u yyyy, HH:MM")
    GUARD_STATUS["castIndex"] = string(instance.guard.ack_cast.ack.proof.index) * " ($tracking_code)"

    _commit = Model.commit(instance.guard)

    GUARD_STATUS["commitIndex"] = _commit.state.index
    GUARD_STATUS["commitRoot"] = _commit.state.root |> digest_pretty_string

    return
end

function castBallot()

    items = QML.get_julia_data(PROPOSAL_BALLOT).values[]
    choices = [i.choice for i in items]

    uuid = UUID(DEME_STATUS["uuid"])
    memberIndex = DEME_STATUS["memberIndex"]
    index = PROPOSAL_METADATA["index"]

    try
        # First picking out an account
        # Then cast vote on a particular proposal
        account = select(uuid, memberIndex, CLIENT)
        Client.cast_vote!(account, index, Selection(choices[1])) # need to add memberIndex
    catch error

        bt = catch_backtrace()

        title = "Casting of the vote failed"
        main_msg = "Check that your ballot is formed corectly as well as that you can reach the ballotbox with your network connection."

        io = IOBuffer()
        
        println(io, main_msg)
        println(io)

        println(io, "Evaluating: castBallot()")
        showerror(io, error)
        println(io, "\n")
        print_simplified_backtrace(io, bt[1:1])
        msg = String(take!(io))

        @emit raiseError(title, msg) 
        @error "castBallot()" exception=(error, bt) # For REPL
    end

    setProposal(index)
    setDeme(uuid, memberIndex)

    return
end

function refreshHome()

    PROPOSAL_METADATA["index"] = 0
    setHome()    

    return
end

function refreshDeme()
    
    account = select(DEME_STATUS["uuid"], DEME_STATUS["memberIndex"], CLIENT)
    Client.update_deme!(account)
    setDeme(DEME_STATUS["uuid"], DEME_STATUS["memberIndex"])

    return
end

function refreshProposal()

    uuid = UUID(DEME_STATUS["uuid"])
    index = PROPOSAL_METADATA["index"]

    account = select(DEME_STATUS["uuid"], DEME_STATUS["memberIndex"], CLIENT)
    instance = select(PROPOSAL_METADATA["index"], account)
    
    if !isnothing(instance.guard)

        Client.check_vote!(account, index)

    else

        Client.get_ballotbox_commit!(account, index)

    end

    setProposal(index)

    return
end

function resetBallot()
    
    index = PROPOSAL_METADATA["index"]
    setProposal(index)

    return
end

function addDeme(invite::Client.Invite)

    account = Client.enroll!(CLIENT, invite)
    Client.update_deme!(account)
    setHome()
    
    return
end

function addDeme(invite_str::QString)

    invite = Parser.unmarshal(invite_str |> String, Client.Invite)
    addDeme(invite)

    return
end

function closeWindow()

    @emit closeWindow()

    return
end

function ErrorMiddleware(handler::Function; name = nameof(handler))

    _esc(x) = x
    _esc(x::AbstractString) = "\"$x\""

    return function(args...)
        _args = join([_esc(i) for i in args], ", ")
        @info "Calling $name($_args)"
        try 
            handler(args...)
        catch error
            
            bt = catch_backtrace()

            title = "Untreated Error"

            io = IOBuffer()
            println(io, "Evaluating: $name($_args)")
            showerror(io, error)
            println(io, "\n")
            print_simplified_backtrace(io, bt[1:1])
            msg = String(take!(io))

            @emit raiseError(title, msg) 
            @error "$name($_args)" exception=(error, bt) # For REPL
        end
    end
end

function load_prototype()

    loadqml((@__DIR__) * "/../qml/Prototype.qml")
    exec()

    return
end

function set_qmlfunction(f::Function; name::Symbol = nameof(f), middleware = [])

    handler(args...) = ErrorMiddleware(f; name)(args...) # To support Revise tracking for ErrorMiddleware
    qmlfunction(string(name), reduce(|>, [handler, middleware...]))

    return
end

function load_view(init::Function = () -> nothing; middleware = [], dir = "", qmldir = joinpath(dirname(@__DIR__), "qml"))

    global CLIENT = Client.load_client(dir)

    for func in [setDeme, setProposal, castBallot, refreshHome, refreshDeme, refreshProposal, resetBallot, addDeme]
        set_qmlfunction(func; middleware)
    end

    loadqml(joinpath(qmldir, "Main.qml"); 
            _USER_DEMES = USER_DEMES,
            _DEME_STATUS = DEME_STATUS,
            _DEME_PROPOSALS = DEME_PROPOSALS,
            _PROPOSAL_METADATA = PROPOSAL_METADATA,
            _PROPOSAL_STATUS = PROPOSAL_STATUS,
            _PROPOSAL_BALLOT = PROPOSAL_BALLOT,
            _GUARD_STATUS = GUARD_STATUS
            )

    init() # What use do I have here actually?
    exec()

    return
end

function julia_main(; dir = "")::Cint

    load_view(; dir) do
        setHome()
    end

end


@setup_workload begin
    dir = joinpath(dirname(@__DIR__), "test", "sample") # This is not compiled so perhaps it's fine?
    __init__()

    @compile_workload begin
        load_view(; dir) do
            setHome()
            setDeme(Base.UUID("033F9207-E4E4-9AAA-02EA-5DDF5E450DD8"), 17)
            closeWindow()
        end

    end
end


function (@main)(ARGS; qmldir = joinpath(dirname(@__DIR__), "qml"))

    #window = create_splash_window()

    if isdefined(Main, :Revise)

        function ReviseHandler(handle)
            return function(args...)
                Main.Revise.revise()
                invokelatest(handle, args...)
            end
        end

        load_view(middleware = [ReviseHandler], dir = get(ENV, "USER_DATA", "")) do
            setHome()
        end

    else
        load_view(; dir = get(ENV, "USER_DATA", ""), qmldir) do
            setHome()
        end
    end

    return
end

export main


end
