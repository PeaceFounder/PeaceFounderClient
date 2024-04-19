using Base.StackTraces

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


# function ordinal_suffix(day)
#     if day in [11, 12, 13]
#         return "th"
#     elseif day % 10 == 1
#         return "st"
#     elseif day % 10 == 2
#         return "nd"
#     elseif day % 10 == 3
#         return "rd"
#     else
#         return "th"
#     end
# end

# # Function to format the date
# function format_date_ordinal(date)
#     # Extract components of the date
#     year = Dates.year(date)
#     month = Dates.format(date, "u")
#     day = Dates.day(date)
#     hour = Dates.hour(date)
#     minute = Dates.minute(date)
    
#     # Combine components with the ordinal suffix
#     formatted_date = string(month, " ", day, ordinal_suffix(day), " ", year, " at ", lpad(hour, 2, '0'), ":", lpad(minute, 2, '0'))
    
#     return formatted_date
# end


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

# Curently unused. Would be useful for print_spec_linfo without regexes
function simplify_type_name(T::Type)
    # Get the simple name of the type without module prefix
    simple_name = string(nameof(T))

    # Determine if T is a parameterized type and if it has actual parameters
    if T isa DataType && !isempty(T.parameters) && T.name.wrapper != nothing
        # Recursively format each parameter
        param_names = join(simplify_type_name.(T.parameters), ", ")
        return "$(simple_name){$param_names}"
    else
        # Return just the simple name for non-parameterized types
        return simple_name
    end
end


function remove_namespaces(s::String)
    # This pattern matches any namespace ending with a dot before a type name
    pattern = r"[\w\.]+\.(\w+)"
    # Replace the full namespace and type with just the type
    return replace(s, pattern => s"\1")
end

function print_spec_linfo(io, frame)

    buf = IOBuffer()
    StackTraces.show_spec_linfo(buf, frame)
    str = take!(buf) |> String

    spec = remove_namespaces(str)
    
    print(io, spec)

    return
end

function print_simplified_backtrace(io, bt)
    frames = StackTraces.stacktrace(bt)
    for frame in frames
        parent_module = StackTraces.parentmodule(frame)

        if !(frame.linfo isa Core.MethodInstance)
            continue
        end

        print_spec_linfo(io, frame)
        println(io)
        println(io, "@ $parent_module")
    end
end
