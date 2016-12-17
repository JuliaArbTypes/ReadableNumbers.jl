module ReadableNumbers

#=
    generating and showing prettier numeric strings
=#     

import Base: STDOUT, parse

export readable, ReadableNumStyle,
       stringpretty, showpretty 

if VERSION < v"0.6"
    split(str::String, sep::Char=" ") = map(String, Base.split(str, sep))  # do not work with SubStrings
end    

# determine locale convention for the fractional (decimal) point
const LOCALE_STR = string( 1 + Float64( 1 // 5 ) )
const FRACPOINT  = LOCALE_STR[ nextind(LOCALE_STR, 1) ]

include("type.jl")
include("dothework.jl")
include("iohelp.jl")


end # module

