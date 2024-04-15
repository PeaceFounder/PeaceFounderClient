function select(predicate::Function, data::Vector)

    N = findfirst(predicate, data)

    @assert !isnothing(N) "No item with given predicate found"

    return data[N]
end

select(predicate::Function, model::QML.JuliaItemModelAllocated) = select(predicate, QML.get_julia_data(model).values[])

select(predicate::Function) = collection -> select(predicate, collection)

select(uuid::UUID, client::Client.DemeClient) = select(account -> account.deme.uuid == uuid, client.accounts)
select(uuid::AbstractString, client::Client.DemeClient) = select(UUID(uuid), client)

select(index::Integer, account::DemeAccount) = select(instance -> instance.index == index, account.proposals)
select(uuid::UUID, account::DemeAccount) = select(instance -> instance.proposal.uuid == uuid, account.instances)


function select(predicate::Function, collection::AbstractVector)

    for item in collection
        if predicate(item)
            return item
        end
    end

    return nothing
end


function reset!(lm, list)

    QML.begin_reset_model(lm)

    data = QML.get_julia_data(lm)

    empty!(data.values[])
    append!(data.values[], list)

    QML.end_reset_model(lm)

    return
end


# The way to print out the interval is 
# more an UI decission. Although it could help improving 
# prining of a proposal and perhaps justify introducing TimeWindow type


function time_period(period::TimePeriod)

    if period < Dates.Second(90)

        seconds = div(period, Dates.Second(1))
        return "$seconds seconds"

    elseif period < Dates.Minute(90)

        minutes = div(period, Dates.Minute(1), RoundUp)
        return "$minutes minutes"

    elseif period < Dates.Hour(36)

        hours = div(period, Dates.Hour(1), RoundUp)
        return "$hours hours"

    else

        # Need to make it two days

        days = div(period, Dates.Day(1), RoundUp)
        return "$days days"

    end

end


function time_window(open::DateTime, closed::DateTime; time = Dates.now())

    if time < open
                
        period = open - time
        period_str = time_period(period)

        return "Opens in $period_str"

    elseif time > closed

        period = time - closed

        if period < Dates.Hour(12)

            period_str = time_period(period)
            return "Closed $period_str ago"

        else

            str = Dates.format(closed, Dates.dateformat"dd-u-yyyy")
            return "Closed on $str"

        end

    else 

        period = closed - time
        period_str = time_period(period)

        return "$period_str remaining"

    end
end

time_window(proposal::Proposal) = time_window(proposal.open, proposal.closed)

function group_slice(collection, n::Int) 

    K = length(collection)

    @assert mod(K, n) == 0

    #s = Vector{T}[]
    s = []

    for i in 1:div(K, n)

        head = 1 + n * (i - 1)
        tail = n * i

        push!(s, collection[head:tail])
    end

    return s
end

function digest_pretty_string(digest::Model.Digest)

    bytes = Model.bytes(digest)[1:16] # Only first 16 are displayed

    str = uppercase(bytes2hex(bytes))
    
    str_pretty = join(group_slice(str, 8), "-")

    return str_pretty
end
