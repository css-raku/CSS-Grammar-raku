use v6;

# specification: http://www.w3.org/TR/2011/REC-CSS2-20110607/propidx.html

grammar CSS::Grammar::CSS21::Properties:ver<20110607.000> {
    proto rule prop { <...> }

    rule prop:sym<azimuth> {:i (azimuth) ':' [$<props>=[<angle> | [[ left\-side | far\-left | left | center\-left | center | center\-right | right | far\-right | right\-side ] || behind ] | leftwards | rightwards | inherit ] | <any>* ] }
    rule prop:sym<background-attachment> {:i (background\-attachment) ':' [$<props>=[scroll | fixed | inherit] | <any>* ] }
    #...
    # font-style - inherited from css1    
}

class CSS::Grammar::CSS21::Properties::Actions {
    method prop:sym<azimuth>($/) {warn "tba: property "~$/.Str }
    method prop:sym<background-attachment>($/) {warn "tba: "~$/.Str };
}
