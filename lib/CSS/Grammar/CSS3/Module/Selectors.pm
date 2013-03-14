use v6;

# CSS3 Selectors Module
# specification: http://www.w3.org/TR/2001/CR-css3-selectors-20090929/
# Notes:
# -- have taken <expr> and <term> from css3-syntax-20030813; which has
#    more detail and structure
# -- have relaxed negation rule to take a list of arguments - in common use
#    and supported  by major browsers.

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
    token nth_functor {:i [nth|first|last|'nth-last']'-'['child'|'of-type']}
    # to compute a.n + b
    proto token nth_expr {*}
    token nth_expr:sym<odd>  {:i'odd'}
    token nth_expr:sym<even> {:i'even'}
    token nth_expr:sym<expr> {:i
        [<a=.int>|$<a_sign>=<[\+\-]>]? $<n>=<[Nn]> [<?before <[\+\-]>><b=.int>]?
        |<b=.int>
    }
    token nth_function {<ident=.nth_functor> '(' <expr=.nth_expr> [')' | <unclosed_paren>]} 

    rule pseudo:sym<nth_child>{':' <nth_function> }
    rule pseudo:sym<function> {':' <function> }
    rule pseudo:sym<class>    {':' <class=.ident> }
    rule pseudo:sym<element2> {'::' <element=.ident> }
 
    rule aterm:sym<unicode_range> {'U+'<unicode_range>}
    rule aterm:sym<ident>         {<!before emx><ident>}

    token negation     {:i':not(' [<type_selector> | <universal> | <id> | <class> | <attrib> | <pseudo>]+ [')' | <unclosed_paren>]}
}

class CSS::Grammar::CSS3::Module::Selectors::Actions {

    method namespace_prefix($/) { make $.node($/) }
    method wildcard($/)         { make $/.Str }
    method type_selector($/)    { make $.node($/) }
    method universal($/)        { make $.node($/) }

    method pseudo:sym<negation>($/) {$.warning('unexpected negation', $/.Str)}

    method attribute_selector:sym<prefix>($/)    { make $/.Str }
    method attribute_selector:sym<suffix>($/)    { make $/.Str }
    method attribute_selector:sym<substring>($/) { make $/.Str }

    method aterm:sym<unicode_range>($/) { make $.node($/) }
    method unicode_range:sym<from_to>($/) {
        # don't produce actual hex chars; could be out of range
        make [ $._from_hex($<from>.Str), $._from_hex($<to>.Str) ];
    }
    method unicode_range:sym<masked>($/) {
        my $mask = $/.Str;
        my $lo = $mask.subst('?', '0'):g;
        my $hi = $mask.subst('?', 'F'):g;

        # don't produce actual hex chars; could be out of range
        make [ $._from_hex($lo), $._from_hex($hi) ];
    }

    method nth_expr:sym<odd>($/)     { make {a => 2, b=> 1} }
    method nth_expr:sym<even>($/)    { make {a => 2 } }
    method nth_expr:sym<expr>($/)    {
        my %node = $.node($/);

        if $<a_sign> {
            %node<a> = $<a_sign>.Str eq '-' ?? -1 !! 1;
        }

        make %node;
    }
    method nth_functor($/)           { make $/.Str.lc }
    method nth_function($/)          { make $.node($/) }
    method pseudo:sym<nth_child>($/) { make $.node($/) }

    method negation($/)     { make $.list($/) }
}

