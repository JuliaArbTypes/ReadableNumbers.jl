import Base: STDOUT

function stringpretty{T<:Real}(x::T, etc...)
    return readable(x, etc...)
end

function showpretty{T<:Real}(io::IO, x::T, etc...)
    str = stringpretty(x, etc...)
    print(io, str)
end

function showpretty{T<:Real}(x::T, etc...)
    str = stringpretty(x, etc...)
    print(STDOUT, str)
end    
