

# parse readable numeric strings

parse_readable{T<:Union{Integer,AbstractFloat}}(::Type{T}, s::String, ch::Char) =
    Base.parse(T, join(split(s,ch),""))

parse_readable{T<:AbstractFloat}(::Type{T}, s::String, ch1::Char, ch2::Char) =
    Base.parse(T, join(split(s,(ch1,ch2)),""))

"""
how many times does char c occur in string s
"""
function count_char(s::String, c::Char)
    r = Regex(string(c))
    return length( matchall(r,s) )
end
