# show 

function show_readable{T<:Real}(io::IO, x::T)
    str = readable(x)
    print(io, str)
end

function show_readable{T<:Real}(x::T)
    str = readable(x)
    print(STDOUT, str)
end    
