use v6;

# CSS3 Selectors Module
# specification: http://www.w3.org/TR/2001/CR-css3-selectors-20090929/
# Notes:
# -- have taken <expr> and <term> on css3-syntax-20030813; which has
#    more detail and structure
# -- have relaxed negation rule to take a list of arguments - in common use
#    and supported  by major browsers.
# ** under construction **

grammar CSS::Grammar::CSS3::Module::Selectors:ver<20090929.000> {

    # inherited combinators: '+' (adjacent), '>' (child)
    token combinator:sym<sibling> {'~'}

    rule selectors {
        <selector> [',' <selector>]*
    }

    rule selector {<simple_selector>[[<.ws>?<combinator><.ws>?]? <simple_selector>]*}
    rule namespace_prefix {[<ident>|<wildcard>]? '|'}
    rule wildcard {'*'}

    token simple_selector { <namespace_prefix>? [<element_name>|<wildcard>] [<negation> | <id> | <class> | <attrib> | <pseudo>]*
                          | [<negation> | <id> | <class> | <attrib> | <pseudo>]+ }

    rule type_selector {<namespace_prefix>? <element_name>}
    
    rule attrib        {'[' <ident> [ <attribute_selector> [<ident>|<string>] ]? ']'}

    rule universal      {<namespace_prefix>? <wildcard>}


    # inherited from base: = ~= |=
    rule attribute_selector:sym<prefix>    {'^='}
    rule attribute_selector:sym<suffix>    {'$='}
    rule attribute_selector:sym<substring> {'*='}

    # pseudo:sym<element> inherited from base 
    rule pseudo:sym<negation> {<negation>}
    rule pseudo:sym<function> {':' <function> }
    rule pseudo:sym<lang>     {':lang(' <lang=.ident> [')' | <unclosed_paren>]}
    rule pseudo:sym<class>    {':' <class=.ident> }
    rule pseudo:sym<element2> {'::' <element=.ident> }
 
    token negation     {:i':not(' [<type_selector> | <universal> | <id> | <class> | <attrib> | <pseudo>]+ [')' | <unclosed_paren>]}
}

class CSS::Grammar::CSS3::Module::Selectors::Actions {

    method selectors($/)        { make $.list($/) }
    method selector($/)         { make $.list($/) }
    method namespace_prefix($/) { make $.node($/) }
    method wildcard($/)         { make $/.Str }
    method simple_selector($/)  { make $.list($/) }
    method type_selector($/)    { make $.node($/) }
    method attrib($/)           { make $.node($/) }
    method universal($/)        { make $.node($/) }

    method pseudo:sym<negation>($/) {$.warning('unexpected negation', $/.Str)}

    method attribute_selector:sym<equals>($/)    { make $/.Str }
    method attribute_selector:sym<includes>($/)  { make $/.Str }
    method attribute_selector:sym<dash>($/)      { make $/.Str }
    method attribute_selector:sym<prefix>($/)    { make $/.Str }
    method attribute_selector:sym<suffix>($/)    { make $/.Str }
    method attribute_selector:sym<substring>($/) { make $/.Str }


    method negation($/)     { make $.list($/) }
    method function($/)     { make $.node($/) }
}

