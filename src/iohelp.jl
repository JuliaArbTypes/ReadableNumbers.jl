import Base: STDOUT


# string

function stringpretty{T<:Real}(x::T, etc...)
    return readable(x, etc...)
end

# show 

function showpretty{T<:Real}(io::IO, x::T, etc...)
    str = stringpretty(x, etc...)
    print(io, str)
end

function showpretty{T<:Real}(x::T, etc...)
    str = stringpretty(x, etc...)
    print(STDOUT, str)
end    


# parse readable numeric strings

parse{T<:Union{Signed,AbstractFloat}}(::Type{T}, s::String, ch::Char) =
    parse(T, join(split(s,ch),""))
parse{T<:AbstractFloat}(::Type{T}, s::String, ch1::Char, ch2::Char) =
    parse(T, join(split(s,(ch1,ch2)),""))
