
# accept extended precision numbers and make them become readable

function readable{T<:Real}(x::T, pns::PrettyNumberStyle=get_pretty_number_style())
    numstr = string(string(x),FRACPOINT)
    return a_readable_number(numstr, pns)
end

function readable(x::String, pns::PrettyNumberStyle=get_pretty_number_style())
    numstr = string(x, FRACPOINT)
    return a_readable_number(numstr, pns)
end    

