
# do the work


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
