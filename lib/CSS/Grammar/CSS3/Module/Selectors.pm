use v6;

# CSS3 Selectors Module
# see http://www.w3.org/TR/2001/CR-css3-selectors-20011113/


grammar CSS::Grammar::CSS3::Module::Selectors {

    rule combinator {'+'|'>'}

    rule selectors {
        <selector> [',' <selector>]*
    }

    rule selector {<simple_selector>[[<.ws>?<combinator><.ws>?]? <simple_selector>]*}

    token simple_selector { <element_name> [<id> | <class> | <attrib> | <pseudo>]*
                          |                [<id> | <class> | <attrib> | <pseudo>]+ }

    

    rule attrib       {'[' <ident> [ <attribute_selector> [<ident>|<string>] ]? ']'}

    # inherited from base: = ~= |=
    rule attribute_selector:sym<prefix>    {'^='}
    rule attribute_selector:sym<suffix>    {'$='}
    rule attribute_selector:sym<substring> {'*='}

    rule pseudo       {':' [<function>|<ident>] }
    token function    {<ident> '(' <expr> [')' | <unclosed_paren>]}
}

class CSS::Grammar::CSS3::Module::Selectors::Actions {

    method selectors($/)       { make $.list($/) }
    method selector($/)        { make $.list($/) }
    method simple_selector($/) { make $.node($/) }
    method attrib($/)          { make $.node($/) }

    method attribute_selector:sym<equals>($/)    { make $/.Str }
    method attribute_selector:sym<includes>($/)  { make $/.Str }
    method attribute_selector:sym<dash>($/)      { make $/.Str }
    method attribute_selector:sym<prefix>($/)    { make $/.Str }
    method attribute_selector:sym<suffix>($/)    { make $/.Str }
    method attribute_selector:sym<substring>($/) { make $/.Str }

    method pseudo($/) {
        my %node = $.node($/);
        %node<ident> = %node<ident>.lc
            if %node.exists('ident');
        make %node;
    }

    method function($/)     { make $.node($/) }
}

