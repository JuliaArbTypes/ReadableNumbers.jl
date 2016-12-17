module ReadableNumbers

import Base: parse

export
  # generating and showing prettier numeric strings
      PrettyNumber, stringpretty, showpretty

if VERSION < v"0.6"
    split(str::String, sep::Char=" ") = map(String, Base.split(str, sep))  # do not work with SubStrings
end    

# determine locale convention for the fractional (decimal) point
const LOCALE_STR = string( 1 + Float64( 1 // 5 ) )
const FRACPOINT  = LOCALE_STR[ nextind(LOCALE_STR, 1) ]


"""
PrettyNumberStyle field naming
    _integral digits_ preceed the fraction_delimiter (decimal point)
    _fractional digits_ follow  the fraction_delimiter (decimal point)
"""
immutable PrettyNumberStyle
    integral_digits_spanned::Int32
    fractional_digits_spanned::Int32
    between_integral_spans::Char
    between_fractional_spans::Char
    fraction_delimiter::String
end


# default values

const IDIGS = 3%Int32                      # integral_digits_spanned
const FDIGS = 5%Int32                      # fractional_digits_spanned
const IBTWN = FRACPOINT != ',' ? ',' : '.' # between_integral_digits
const FBTWN = '_'                          # between_fractional_digits


# constructors cover likely argument orderings and omisions 

PrettyNumberStyle() = PrettyNumberStyle(IDIGS, FDIGS, IBTWN, FBTWN, FMARK)

function PrettyNumberStyle{I<:Integer}(
             idigs::I, rdigs::I=FDIGS%I, ibtwn::Char=IBTWN, rbtwn::Char=FBTWN, fracpt::Char=FRACPT)
    pns = PrettyNumberStyle( idigs%Int32, rdigs%Int32, ibtwn, rbtwn, fracpt )
    set_pretty_number_style(pns)
    return pns
end    

PrettyNumberStyle{I<:Integer}(
    ibtwn::Char, rbtwn::Char=FBTWN, idigs::I=IDIGS%I, rdigs::I=FDIGS%I, fracpt::Char=FRACPT
    ) =
    PrettyNumberStyle(idigs, rdigs, ibtwn, rbtwn, fracpt)
PrettyNumberStyle{I<:Integer}(
    idigs::I, ibtwn::Char, rdigs::I=FDIGS%I, rbtwn::Char=FBTWN, fracpt::Char=FRACPT
    ) =
    PrettyNumberStyle( idigs%Int32, rdigs%Int32, ibtwn, rbtwn, fracpt )
PrettyNumberStyle{I<:Integer}(
    ibtwn::Char, idigs::I, rbtwn::Char=FBTWN, rdigs::I=FDIGS%I, fracpt::Char=FRACPT
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
    local numstr, ipart, fpart, iread, fread, readable
    numstr = string(string(x), FRACPOINT)
    ipart, fpart = split(numstr, FRACPOINT)[1:2]
    iread = ifelse( ipart == "", "0", 
                    readable_integer(ipart, pns.integral_digits_spanned, pns.between_integral_spans) )
    fread = ifelse( fpart == "", "" , 
                    readable_fraction(fpart, pns.fractional_digits_spanned, pns.between_fractional_spans) )
    readable = fpart == "" ? iread : string(iread, pns.fraction_delimiter, fread)
    return readable
end    




# do the work

function find_exponent_delimiter(str::String)
    idx = sum(findfirst.(str, ('e','E','p','P')))
    dlm = idx==0 ?  '⌟'  :  str[nextidn(str,idx-1)]
    return idx, dlm
end    

function readable_nonneg_integer{I<:Integer}(s::String, digits_spanned::I, group_separator::Char)
    n = length(s)
    n==0 && return "0"

    sinteger, sexponent =
        if contains(s,"e")           # followed by nonneg decimal exponent
           split(s,'e')
        elseif contains(s,"E")       # followed by nonneg decimal exponent
           split(s,'E')
        elseif contains(s,"p")       # followed by nonneg hexadecimal exponent
           split(s,'p')
        elseif contains(s,"P")       # followed by nonneg hexadecimal exponent
           split(s,'P')   
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





export
  # generating and showing prettier numeric strings
      stringpretty, showpretty,
  # span char: UTF8 char used to separate spans of contiguous digits
      betweenNums , betweenInts , betweenFlts ,
      betweenNums!, betweenInts!, betweenFlts!,
  # span size: the number of contiguous digits used to form a span
      numsSpanned , intsSpanned , fltsSpanned ,
      numsSpanned!, intsSpanned!, fltsSpanned!

# module level control of numeric string formatting (span char, span size)
#   span char and span size are each the only value within a const vector
#   span char and span size are assignable for all parts of numeric strings
#     or they may be assigned to constrain
#        (a) integers & integral part of float strings
#        (b) floats of abs() < 1.0 & the fractional part of float strings

const charBetweenNums = '_'
const charBetweenInts = ','
const charBetweenFlts = '_'

const lengthOfNumSpan =  3
const lengthOfIntSpan =  3
const lengthOfFltSpan =  5

const ints_spanned = [ lengthOfIntSpan ]; intsSpanned() = ints_spanned[1]
const between_ints = [ charBetweenInts ]; betweenInts() = between_ints[1]
const flts_spanned = [ lengthOfFltSpan ]; fltsSpanned() = flts_spanned[1]
const between_flts = [ charBetweenFlts ]; betweenFlts() = between_flts[1]


#  make numeric strings easier to read


stringpretty(val::Signed, group::Int, sep::Char=betweenInts()) =
    prettyInteger(val, group, sep)
stringpretty(val::Signed, sep::Char, group::Int=intsSpanned()) =
    stringpretty(val, group, sep)
function stringpretty(val::Signed)
    group, sep = intsSpanned(), betweenInts()
    stringpretty(val, group, sep)
end

stringpretty{T<:Signed}(val::Rational{T}, group::Int, sep::Char=betweenInts()) =
    string(prettyInteger(val.num, group, sep),"//",prettyInteger(val.den, group, sep))
stringpretty{T<:Signed}(val::Rational{T}, sep::Char, group::Int=intsSpanned()) =
    stringpretty(val, group, sep)
function stringpretty{T<:Signed}(val::Rational{T})
    group, sep = intsSpanned(), betweenInts()
    stringpretty(val, group, sep)
end

stringpretty(val::AbstractFloat,
        intGroup::Int, fracGroup::Int, intSep::Char, fltSep::Char) =
    prettyFloat(val, intGroup, fracGroup, intSep, fltSep)
stringpretty(val::AbstractFloat,
        intGroup::Int, fracGroup::Int, sep::Char=betweenFlts()) =
    stringpretty(val, intGroup, fracGroup, sep, sep)
stringpretty(val::AbstractFloat,
        group::Int, intSep::Char, fltSep::Char) =
    stringpretty(val, group, group, intSep, fltSep)
stringpretty(val::AbstractFloat,
        group::Int, sep::Char=betweenFlts()) =
    stringpretty(val, group, group, sep, sep)
stringpretty(val::AbstractFloat,
        intSep::Char, fltSep::Char, intGroup::Int, fracGroup::Int) =
    stringpretty(val, intGroup, fracGroup, intSep, fltSep)
stringpretty(val::AbstractFloat,
        intSep::Char, fltSep::Char, group::Int) =
    stringpretty(val, group, group, intSep, fltSep)
stringpretty(val::AbstractFloat,
        sep::Char, intGroup::Int, fracGroup::Int) =
    stringpretty(val, intGroup, fracGroup, sep, sep)
stringpretty(val::AbstractFloat,
        sep::Char, group::Int=fltsSpanned()) =
    stringpretty(val, group, group, sep, sep)
function stringpretty(val::AbstractFloat)
    group, sep = fltsSpanned(), betweenFlts()
    stringpretty(val, group, group, sep, sep)
end


function stringpretty(val::Real,
          intGroup::Int, fracGroup::Int, intSep::Char, fltSep::Char)
    if !prettyfiable(val)
       ty = typeof(val)
       throw(ErrorException("type $ty is not supported"))
    end
    prettyFloat(string(val), intGroup, fracGroup, intSep, fltSep)
end
stringpretty(val::Real, intGroup::Int, fracGroup::Int, sep::Char=betweenFlts()) =
    stringpretty(val, intGroup, fracGroup, sep, sep)
stringpretty(val::Real, group::Int, intSep::Char, fltSep::Char) =
    stringpretty(val, group, group, intSep, fltSep)
stringpretty(val::Real, group::Int, sep::Char=betweenFlts()) =
    stringpretty(val, group, group, sep, sep)
stringpretty(val::Real, intSep::Char, fltSep::Char, intGroup::Int, fracGroup::Int) =
    stringpretty(val, intGroup, fracGroup, intSep, fltSep)
stringpretty(val::Real, intSep::Char, fltSep::Char, group::Int) =
    stringpretty(val, group, group, intSep, fltSep)
stringpretty(val::Real, sep::Char, intGroup::Int, fracGroup::Int) =
    stringpretty(val, intGroup, fracGroup, sep, sep)
stringpretty(val::Real, sep::Char, group::Int=fltsSpanned()) =
    stringpretty(val, group, group, sep, sep)
function stringpretty(val::Real)
    group, sep = fltsSpanned(), betweenFlts()
    stringpretty(val, group, group, sep, sep)
end

function stringpretty(val::String)
    int_group, flt_group = intsSpanned(), fltsSpanned()
    int_sep, flt_sep = betweenInts(), betweenFlts()
    str = prettyFloat(val, int_group, flt_group, int_sep, flt_sep)
    return str
end

# show easy-to-read numbers

showpretty(io::IO, val::Signed, group::Int, sep::Char=betweenInts()) =
    print(io, stringpretty(val, group, sep))
showpretty(io::IO, val::Signed, sep::Char, group::Int=intsSpanned()) =
    print(io, stringpretty(val, group, sep))
function showpretty(io::IO, val::Signed)
    group, sep = intsSpanned(), betweenInts()
    print(io, stringpretty(val, group, sep))
end

showpretty{T<:Signed}(io::IO, val::Rational{T}, group::Int, sep::Char=betweenInts()) =
    print(io,prettyInteger(val.num, group, sep),"//",prettyInteger(val.den, group, sep))
showpretty{T<:Signed}(io::IO, val::Rational{T}, sep::Char, group::Int=intsSpanned()) =
    print(io, stringpretty(val, group, sep))
function showpretty{T<:Signed}(io::IO, val::Rational{T})
    group, sep = intsSpanned(), betweenInts()
    print(io, stringpretty(val, group, sep))
end

function showpretty(io::IO, val::AbstractFloat)
    group, sep = fltsSpanned(), betweenFlts()
    print(io, stringpretty(val, group, group, sep, sep))
end
function showpretty(io::IO, val::AbstractFloat, group::Int)
    sep = betweenFlts()
    print(io, stringpretty(val, group, group, sep, sep))
end
function showpretty(io::IO, val::AbstractFloat, sep::Char)
    group = fltsSpanned()
    print(io, stringpretty(val, group, group, sep, sep))
end
showpretty(io::IO, val::AbstractFloat, prettyFormat...) =
    print(io, stringpretty(val, prettyFormat...))



function showpretty(io::IO, val::Real,
          intGroup::Int, fracGroup::Int, intSep::Char, fltSep::Char)
    if !prettyfiable(val)
       ty = typeof(val)
       throw(ErrorException("type $ty is not supported"))
    end
    print(io, stringpretty(val, intGroup, fracGroup, intSep, fltSep))
end
function showpretty(io::IO, val::Real)
    group, sep = fltsSpanned(), betweenFlts()
    showpretty(io, val, group, group, sep, sep)
end
function showpretty(io::IO, val::Real, group::Int)
    sep = betweenFlts()
    showpretty(io, val, group, group, sep, sep)
end
function showpretty(io::IO, val::Real, sep::Char)
    group = fltsSpanned()
    showpretty(io, val, group, group, sep, sep)
end
showpretty(io::IO, val::Real, prettyFormat...) =
    print(io, stringpretty(val, prettyFormat...))

showpretty(io::IO, val::String, prettyFormat...) =
    print(io, stringpretty(val, prettyFormat...))

function showpretty(io::IO, val::String)
     str = stringpretty(val)
     print(io, str)
end
  
# show on STDOUT


showpretty(val::Signed, group::Int, sep::Char=betweenInts()) =
    showpretty(Base.STDOUT, val, group, sep)
showpretty(val::Signed, sep::Char, group::Int=intsSpanned()) =
    showpretty(Base.STDOUT, val, group, sep)
function showpretty(val::Signed)
    group, sep = intsSpanned(), betweenInts()
    showpretty(Base.STDOUT, val, group, sep)
end

showpretty{T<:Signed}(val::Rational{T}, group::Int, sep::Char=betweenInts()) =
    string(prettyInteger(val.num, group, sep),"//",prettyInteger(val.den, group, sep))
showpretty{T<:Signed}(val::Rational{T}, sep::Char, group::Int=intsSpanned()) =
    showpretty(Base.STDOUT, val, group, sep)
function showpretty{T<:Signed}(val::Rational{T})
    group, sep = intsSpanned(), betweenInts()
    showpretty(Base.STDOUT, val, group, sep)
end

function showpretty(val::AbstractFloat, intGroup::Int, fracGroup::Int, intSep::Char, fltSep::Char)
    showpretty(Base.STDOUT, val, intGroup, fracGroup, intSep, fltSep)
end
showpretty(val::AbstractFloat, group::Int) =
    showpretty(Base.STDOUT, val, group)
showpretty(val::AbstractFloat, sep::Char)  =
    showpretty(Base.STDOUT, val, sep)
showpretty(val::AbstractFloat, prettyFormat...) =
    showpretty(Base.STDOUT, val, prettyFormat...)


function showpretty{T<:Real}(val::T, intGroup::Int, fracGroup::Int, intSep::Char, fltSep::Char)
    if !prettyfiable(val)
       throw(ErrorException("type $T is not supported"))
    end
    showpretty(Base.STDOUT, val, intGroup, fracGroup, intSep, fltSep)
end
showpretty(val::Real, group::Int) =
    showpretty(Base.STDOUT, val, group)
showpretty(val::Real, sep::Char)  =
    showpretty(Base.STDOUT, val, sep)
showpretty(val::Real, prettyFormat...) =
    showpretty(Base.STDOUT, val, prettyFormat...)

showpretty(val::String, prettyFormat...) =
    showpretty(Base.STDOUT, val, prettyFormat...)
showpretty(val::String) =
    showpretty(Base.STDOUT, val)

# accept integers and floats

prettyInteger{T<:Signed}(val::T, group::Int, span::Char) =
    integerString(string(val), group, span)

prettyFloat{T<:AbstractFloat}(val::T,
  intGroup::Int, fracGroup::Int, intSep::Char, fltSep::Char) =
    prettyFloat(string(val), intGroup, fracGroup, intSep, fltSep)

prettyFloat{T<:AbstractFloat}(val::T,
  intGroup::Int, fracGroup::Int, span::Char) =
    prettyFloat(string(val), intGroup, fracGroup, span, span)

prettyFloat{T<:AbstractFloat}(val::T,
  group::Int, intSep::Char, fltSep::Char) =
    prettyFloat(string(val), group, intSep, fltSep)

prettyFloat{T<:AbstractFloat}(val::T,  group::Int, span::Char) =
    prettyFloat(string(val), group, span, span)

# handle integer and float strings

splitstr(str::String, at::String) = map(String, split(str, at))

prettyInteger(s::String, group::Int, span::Char) =
    integerString(s, group, span)

function prettyFloat(s::String, intGroup::Int, fracGroup::Int, intSep::Char, fltSep::Char)
    sinteger, sfrac =
        if contains(s,".")
           splitstr(s,".")
        else
           s, ""
        end

    istr = integerString(sinteger, intGroup, intSep)
    if sfrac == ""
       istr
    else
       fstr = fractionalString(sfrac, fracGroup, fltSep)
       string(istr, ".", fstr)
    end
end

prettyFloat(s::String, group::Int, span::Char) =
    prettyFloat(s, group, group, span, span)

prettyFloat(s::String, group::Int, intSep::Char, fltSep::Char) =
    prettyFloat(s, group, group, intSep, fltSep)

prettyFloat(s::String, intGroup::Int, fracGroup::Int, span::Char) =
    prettyFloat(s, intGroup, fracGroup, span, span)

# do the work

function nonnegIntegerString(s::String, group::Int, span::Char)
    n = length(s)
    n==0 && return "0"

    sinteger, sexponent =
        if contains(s,"e")
           splitstr(s,"e")
        else
           s, ""
        end

    n = length(sinteger)

    fullgroups, finalgroup = divrem(n, group)

    sv = convert(Vector{Char},sinteger)
    p = repeat(" ", n+(fullgroups-1)+(finalgroup!=0))
    pretty = convert(Vector{Char},p)

    sourceidx = n
    targetidx = length(pretty)
    for k in fullgroups:-1:1
        pretty[(targetidx-group+1):targetidx] = sv[(sourceidx-group+1):sourceidx]
        sourceidx -= group
        targetidx -= group
        if k > 1
            pretty[targetidx] = span
            targetidx -= 1
        end
    end

    if finalgroup > 0
        if fullgroups > 0
            pretty[targetidx] = span
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

function integerString(s::String, group::Int, span::Char)
    if s[1] != "-"
       nonnegIntegerString(s, group, span)
    else
       s1 = string(s[2:end])
       pretty = nonnegIntegerString(s1, group, span)
       string("-", pretty)
    end
end

function fractionalString(s::String, group::Int, span::Char)
    sfrac, sexponent =
        if contains(s,"e")
           map(String, split(s,"e"))
        else
           s, ""
        end

    pretty = reverse(nonnegIntegerString(reverse(sfrac), group, span))

    if length(sexponent) != 0
       string(pretty,"e",sexponent)
    else
       pretty
    end
end

# get and set shared parameters


function intsSpanned!(n::Int)
    n = max(0,n)
    ints_spanned[1]   = n
    nothing
end
intsSpanned(n::Int) = intsSpanned!(n)

function fltsSpanned!(n::Int)
    n = max(0,n)
    fltsSpanned[1]   = n
    nothing
end
fltsSpanned(n::Int) = fltsSpanned!(n)

numsSpanned() = (intsSpanned() == fltsSpanned()) ? intsSpanned() : (intsSpanned(), fltsSpanned())
function numsSpanned!(n::Int)
    n = max(0,n)
    intsSpanned!(n)
    fltsSpanned!(n)
    nothing
end
numsSpanned(n::Int) = numsSpanned!(n)


betweenNums() = (betweenInts() == betweenFlts()) ? betweenInts() : (betweenInts(), betweenFlts())
function betweenNums!(ch::Char)
    betweenFlts!(ch)
    betweenInts!(ch)
    nothing
end
betweenNums!(s::String) = betweenNums!(s[1])
betweenNums(ch::Int)    = betweenNums!(ch)
betweenNums(s::String)  = betweenNums!(s)

function betweenInts!(ch::Char)
    between_ints[1] = ch
    nothing
end
betweenInts(ch::Char)  = betweenInts!(ch)
betweenInts(s::String) = betweenInts!(s[1])

function betweenFlts!(ch::Char)
    between_flts[1] = ch
    nothing
end
betweenFlts(ch::Char)  = betweenFlts!(ch)
betweenFlts(s::String) = betweenFlts!(s[1])

# is this a type that can be handled above
function prettyfiable{T<:Real}(val::T)
    try
        convert(BigFloat,val); true
    catch
        false
    end
end

# parse pretty numeric strings
parse{T<:Union{Signed,AbstractFloat}}(::Type{T}, s::String, ch::Char) =
    parse(T, join(split(s,ch),""))
parse{T<:AbstractFloat}(::Type{T}, s::String, ch1::Char, ch2::Char) =
    parse(T, join(split(s,(ch1,ch2)),""))

end # module
