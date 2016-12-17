module ReadableNumbers

#=
    generating and showing prettier numeric strings
=#     

import Base: parse

export readable, PrettyNumberStyle,
       stringpretty, showpretty 

if VERSION < v"0.6"
    split(str::String, sep::Char=" ") = map(String, Base.split(str, sep))  # do not work with SubStrings
end    

# determine locale convention for the fractional (decimal) point
const LOCALE_STR = string( 1 + Float64( 1 // 5 ) )
const FRACPOINT  = LOCALE_STR[ nextind(LOCALE_STR, 1) ]


"""
PrettyNumberStyle field naming
    _integral digits_ preceed the fraction_marker (decimal point)
    _fractional digits_ follow  the fraction_marker (decimal point)
"""
immutable PrettyNumberStyle
    integral_digits_spanned::Int32
    fractional_digits_spanned::Int32
    between_integral_spans::Char
    between_fractional_spans::Char
    between_parts::Char
end


# default values

const IDIGS = 3%Int32                      # integral_digits_spanned
const FDIGS = 5%Int32                      # fractional_digits_spanned
const IBTWN = FRACPOINT != ',' ? ',' : '.' # between_integral_digits
const FBTWN = '_'                          # between_fractional_digits


# constructors cover likely argument orderings and omisions 

PrettyNumberStyle() = PrettyNumberStyle(IDIGS, FDIGS, IBTWN, FBTWN, FRACPOINT)

function PrettyNumberStyle{I<:Integer}(
             idigs::I, rdigs::I=FDIGS%I, ibtwn::Char=IBTWN, rbtwn::Char=FBTWN, fracpt::Char=FRACPOINT)
    pns = PrettyNumberStyle( idigs%Int32, rdigs%Int32, ibtwn, rbtwn, fracpt )
    set_pretty_number_style!(pns)
    return pns
end    

PrettyNumberStyle{I<:Integer}(
    ibtwn::Char, rbtwn::Char=FBTWN, idigs::I=IDIGS%I, rdigs::I=FDIGS%I, fracpt::Char=FRACPOINT
    ) =
    PrettyNumberStyle(idigs, rdigs, ibtwn, rbtwn, fracpt)
PrettyNumberStyle{I<:Integer}(
    idigs::I, ibtwn::Char, rdigs::I=FDIGS%I, rbtwn::Char=FBTWN, fracpt::Char=FRACPOINT
    ) =
    PrettyNumberStyle( idigs%Int32, rdigs%Int32, ibtwn, rbtwn, fracpt )
PrettyNumberStyle{I<:Integer}(
    ibtwn::Char, idigs::I, rbtwn::Char=FBTWN, rdigs::I=FDIGS%I, fracpt::Char=FRACPOINT
    ) =
    PrettyNumberStyle(idigs, rdigs, ibtwn, rbtwn, fracpt)


# remember the most recent pretty number style

const PRETTY_NUMBER_STYLE_HOLDER = [ PrettyNumberStyle() ]
function get_pretty_number_style()
    return PRETTY_NUMBER_STYLE_HOLDER[1]
end    
function set_pretty_number_style!(pns::PrettyNumberStyle)
    PRETTY_NUMBER_STYLE_HOLDER[1] = pns
    return nothing
end    

# accept extended precision numbers and make them become readable

function readable{T<:Real}(x::T, pns::PrettyNumberStyle=get_pretty_number_style())
    numstr = string(string(x),FRACPOINT)
    return a_readable_number(numstr, pns)
end

function readable(x::String, pns::PrettyNumberStyle=get_pretty_number_style())
    numstr = string(x, FRACPOINT)
    return a_readable_number(numstr, pns)
end    

function a_readable_number(numstr::String, pns::PrettyNumberStyle)
    local ipart, fpart, iread, fread, readable
    ipart, fpart = split(numstr, FRACPOINT)[1:2]
    iread = ifelse( ipart == "", "0", 
                    readable_integer(ipart, pns.integral_digits_spanned, pns.between_integral_spans) )
    fread = ifelse( fpart == "", "" , 
                    readable_fraction(fpart, pns.fractional_digits_spanned, pns.between_fractional_spans) )
    readable = (fpart == "") ? iread : string(iread, pns.between_parts, fread)
    return readable
end    



include("dothework.jl")
include("iohelp.jl")


end # module

