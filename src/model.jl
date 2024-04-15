mutable struct DemeItem
    uuid::String
    title::String
    #commitIndex::Int # commitIndex
    memberCount::Int # groupSize
end


mutable struct ProposalItem
    index::Int # proposalIndex or simply index
    title::String
    voterCount::Int
    castCount::Int
    isVotable::Bool
    isCast::Bool
    isTallied::Bool
    timeWindow::String
end

mutable struct BallotQuestion
    question::String
    options::Vector{String}
    choice::Int
end

function item(account::DemeAccount)


    uuid = uppercase(string(account.deme.uuid))
    title = account.deme.title
    memberCount = account.commit.state.member_count # could shorten state(account).member_count

    return DemeItem(uuid, title, memberCount)
end


function item(instance::ProposalInstance)

    index = instance.index
    title = instance.proposal.summary
    voterCount = instance.proposal.anchor.member_count
    #castCount = isnothing(instance.commit) ? 0 : instance.commit.state.index
    castCount = isnothing(Model.commit(instance)) ? 0 : Model.commit(instance).state.index
    
    #isVotable = Client.isvotable(instance)
    isVotable = Client.isopen(instance)
    isTallied = Client.istallied(instance)
    isCast = !isnothing(instance.guard)
    timeWindow = time_window(instance.proposal)

    return ProposalItem(index, title, voterCount, castCount, isVotable, isCast, isTallied, timeWindow)
end

function ballot(instance::ProposalInstance)

    question = "" # Until ballot type gets fixed
    options = instance.proposal.ballot.options
    
    pushfirst!(options, "Not Selected")
    choice = 0 

    return BallotQuestion(question, options, choice)
end
