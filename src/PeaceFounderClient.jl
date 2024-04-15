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

include("utils.jl")
include("model.jl")


global CLIENT::DemeClient = DemeClient()

global USER_DEMES::JuliaItemModel
global DEME_STATUS::JuliaPropertyMap
global DEME_PROPOSALS::JuliaItemModel 
global PROPOSAL_METADATA::JuliaPropertyMap
global PROPOSAL_STATUS::JuliaPropertyMap
global PROPOSAL_BALLOT::JuliaItemModel
global GUARD_STATUS::JuliaPropertyMap

function __init__()

    global USER_DEMES = JuliaItemModel(DemeItem[])

    global DEME_STATUS = JuliaPropertyMap(
        "uuid" => "UNDEFINED",
        "title" => "Local democratic community",
        "demeSpec" => "2AAE6C35 C94FCFB4 15DBE95F 408B9CE9 1EE846ED",
        "memberIndex" => 21,
        "commitIndex" => 89,
        "memberCount" => 16
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
        "pseudonym" => "2AAE6C35 C94FCFB4 15DBE95F 408B9CE9 1EE846ED",
        "timestamp" => "June 15, 2009 1:45 PM",
        "castIndex" => 0,
        "commitIndex" => 0,
        "commitRoot" => "2AAE6C35 C94FCFB4 15DBE95F 408B9CE9 1EE846ED"
    )

    return
end


setHome() = reset!(USER_DEMES, DemeItem[item(i) for i in CLIENT.accounts])


function setDeme(uuid::QString)

    (; commit, proposals, deme, guard) = select(uuid, CLIENT)

    reset!(DEME_PROPOSALS, ProposalItem[item(instance) for instance in proposals])
    
    DEME_STATUS["uuid"] = QString(uppercase(string(deme.uuid)))
    DEME_STATUS["title"] = deme.title

    #@infiltrate

    DEME_STATUS["memberCount"] = commit.state.member_count

    DEME_STATUS["memberIndex"] = guard.ack.proof.index
    DEME_STATUS["commitIndex"] = commit.state.index

    DEME_STATUS["demeSpec"] = Model.digest(deme, Model.hasher(deme)) |> digest_pretty_string
    
    return
end

setDeme(uuid::UUID) = setDeme(QString(string(uuid)))


function setProposal(index::Int32)

    account = select(DEME_STATUS["uuid"], CLIENT)
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

    account = select(DEME_STATUS["uuid"], CLIENT)
    instance = select(PROPOSAL_METADATA["index"], account)

    GUARD_STATUS["pseudonym"] = Model.digest(Model.pseudonym(instance.guard.vote), Model.hasher(account.deme)) |> digest_pretty_string
    GUARD_STATUS["timestamp"] = string(instance.guard.ack_cast.receipt.timestamp)
    GUARD_STATUS["castIndex"] = instance.guard.ack_cast.ack.proof.index

    _commit = Model.commit(instance.guard)

    GUARD_STATUS["commitIndex"] = _commit.state.index
    GUARD_STATUS["commitRoot"] = _commit.state.root |> digest_pretty_string

    return
end


# TODO: If cast_vote fails we need to prevent moving to the next page
function castBallot()

    items = QML.get_julia_data(PROPOSAL_BALLOT).values[]
    choices = [i.choice for i in items]

    uuid = UUID(DEME_STATUS["uuid"])
    index = PROPOSAL_METADATA["index"]

    try
        Client.cast_vote!(CLIENT, uuid, index, Selection(choices[1]))
    catch
        @warn "Casting of the ballot have failed"
        resetBallot()
    end

    setProposal(index)
    setDeme(uuid)

    return
end


function refreshHome()

    PROPOSAL_METADATA["index"] = 0
    setHome()    

    return
end


function refreshDeme()

    Client.update_deme!(CLIENT, UUID(string(DEME_STATUS["uuid"])))
    setDeme(DEME_STATUS["uuid"])

    return
end


function refreshProposal()

    uuid = UUID(DEME_STATUS["uuid"])
    index = PROPOSAL_METADATA["index"]

    account = select(DEME_STATUS["uuid"], CLIENT)
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


function ErrorMiddleware(handler::Function; name = nameof(handler))

    _esc(x) = x
    _esc(x::AbstractString) = "\"$x\""

    return function(args...)
        _args = join([_esc(i) for i in args], ", ")
        @info "Calling $name($_args)"
        try 
            handler(args...)
        catch error
            @error "$name($_args)" exception=(error, catch_backtrace())
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


function load_view(init::Function = () -> nothing; middleware = [])

    for func in [setDeme, setProposal, castBallot, refreshHome, refreshDeme, refreshProposal, resetBallot, addDeme]
        set_qmlfunction(func; middleware)
    end

    loadqml((@__DIR__) * "/../qml/Bridge.qml"; 
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

function julia_main()::Cint

    load_view() do
        setHome()
    end

end

end
