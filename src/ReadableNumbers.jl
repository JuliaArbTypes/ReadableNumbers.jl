module ReadableNumbers

import Base: parse

export readable, PrettyNumberStyle
  #=
    generating and showing prettier numeric strings
      PrettyNumber, stringpretty, showpretty
  =#     

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





# do the work

function readable_nonneg_integer{I<:Integer}(s::String, digits_spanned::I, group_separator::Char)
    n = length(s)
    n==0 && return "0"

    sinteger, sexponent =
        if contains(s,"e")
           split(s,'e')
        else
           s, ""
        end

    n = length(sinteger)

    fullgroups, finalgroup = divrem(n, digits_spanned)

    sv = convert(Vector{Char},sinteger)
    p = repeat(" ", n+(fullgroups-1)+(finalgroup!=0))
    pretty = convert(Vector{Char},p)

    sourceidx = n
    targetidx = length(pretty)
    for k in fullgroups:-1:1
        pretty[(targetidx-digits_spanned+1):targetidx] = sv[(sourceidx-digits_spanned+1):sourceidx]
        sourceidx -= digits_spanned
        targetidx -= digits_spanned
        if k > 1
            pretty[targetidx] = group_separator
            targetidx -= 1
        end
    end

    if finalgroup > 0
        if fullgroups > 0
            pretty[targetidx] = group_separator
            targetidx -= 1
        end
        pretty[(targetidx-finalgroup+1):targetidx] = sv[(sourceidx-finalgroup+1):sourceidx]
    end

    prettystring = convert(String, pretty)

    if length(sexponent) != 0
       string(prettystring,"e",sexponent)
    else
       prettystring
    end
end

function readable_integer{I<:Integer}(s::String, digits_spanned::I, group_separator::Char)
    if s[1] != "-"
       readable_nonneg_integer(s, digits_spanned, group_separator)
    else
       s1 = string(s[2:end])
       pretty = readable_nonneg_integer(s1, digits_spanned, group_separator)
       string("-", pretty)
    end
end

function readable_fraction{I<:Integer}(s::String, digits_spanned::I, group_separator::Char)
    sfrac, sexponent =
        if contains(s,"e")
           split(s,'e')
        else
           s, ""
        end

    pretty = reverse(readable_nonneg_integer(reverse(sfrac), digits_spanned, group_separator))

    if length(sexponent) != 0
       string(pretty,"e",sexponent)
    else
       pretty
    end
end



# parse readable numeric strings

parse{T<:Union{Signed,AbstractFloat}}(::Type{T}, s::String, ch::Char) =
    parse(T, join(split(s,ch),""))
parse{T<:AbstractFloat}(::Type{T}, s::String, ch1::Char, ch2::Char) =
    parse(T, join(split(s,(ch1,ch2)),""))


end # module

