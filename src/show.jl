# show 

function show_readable(io::IO, x::T) where {T <: Real}
    str = readable(x)
    print(io, str)
end

function show_readable(x::T) where {T <: Real}
    str = readable(x)
    print(STDOUT, str)
end    

