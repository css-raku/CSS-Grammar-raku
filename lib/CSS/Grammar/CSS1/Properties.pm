use v6;

# based on 

grammar CSS::Grammar::CSS1::Properties {

 rule prop:sym<font\-style> {:i (font\-style) ':' [$<props>=[normal|bold|oblique] | <any>* ] }

}

class CSS::Grammar::CSS1::Properties::Actions {
    method prop:sym<font-style>($/) {warn "tba: "~$/.Str};
}
