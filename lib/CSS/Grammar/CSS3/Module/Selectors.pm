use v6;

# CSS3 Selectors Module
# specification: http://www.w3.org/TR/2001/CR-css3-selectors-20090929/
# Notes:
# -- have relaxed negation rule to take a list of arguments - in common use
#    and supported  by major browsers.

grammar CSS::Grammar::CSS3::Module::Selectors:ver<20090929.000> {

    # extensions:
    # ----------
    # inherited combinators: '+' (adjacent), '>' (child)
    token combinator:sym<sibling> {'~'}

    # allow '::' element selectors
    rule pseudo:sym<element2> {'::'<element=.ident>}
 
    rule namespace_prefix {[<ident>|<wildcard>]?'|'}
    rule wildcard {'*'}

    token simple_selector { <namespace_prefix>? [<element_name>|<wildcard>] [<id> | <class> | <attrib> | <pseudo>]*
                          | [<id> | <class> | <attrib> | <pseudo>]+ }

    rule type_selector {<namespace_prefix>? <element_name>}
    
    rule attrib        {'[' <ident> [ <attribute_selector> [<ident>|<string>] ]? ']'}

    rule universal      {<namespace_prefix>? <wildcard>}

    rule aterm:sym<unicode_range> {'U+'<unicode_range>}
    rule aterm:sym<ident>         {<!before emx><ident>}

    # inherited from base: = ~= |=
    rule attribute_selector:sym<prefix>    {'^='}
    rule attribute_selector:sym<suffix>    {'$='}
    rule attribute_selector:sym<substring> {'*='}

    token nth_functor {:i[nth|first|last|'nth-last']'-'['child'|'of-type']}
    # to compute a.n + b
    proto token nth_args {*}
    token nth_args:sym<odd>   {:i 'odd' }
    token nth_args:sym<even>  {:i 'even' }
    token nth_args:sym<expr> {
        <ws>?
        [$<a_sign>=[\+|\-]? <a=.posint>? $<n>=<[Nn]> <ws>? [$<b_sign>=[\+|\-] <ws>? <b=.posint>]?
        |<b=.posint>
        ]<ws>?
    }

    rule pseudo_function:sym<nth_selector> {<ident=.nth_functor>'(' [<args=.nth_args> ')'| <bad_args> ')']} 
    rule negation_args {[<type_selector> | <universal> | <id> | <class> | <attrib> | $<nested>=[<?before [:i':not(']><pseudo>] | <pseudo> | <bad_arg> ]+}
    rule pseudo_function:sym<negation>  {:i'not(' [ <negation_args> ')'| <bad_args> ')']}
}

class CSS::Grammar::CSS3::Module::Selectors::Actions {

    method namespace_prefix($/) { make $.node($/) }
    method wildcard($/)         { make $/.Str }
    method type_selector($/)    { make $.node($/) }
    method universal($/)        { make $.node($/) }

    method attribute_selector:sym<prefix>($/)    { make $/.Str }
    method attribute_selector:sym<suffix>($/)    { make $/.Str }
    method attribute_selector:sym<substring>($/) { make $/.Str }

    method aterm:sym<unicode_range>($/) { make $.node($/) }
    method pseudo_function:sym<nth_selector>($/)  {
        return $.warning('usage '~$<ident>~'(an+b) e.g "4" "3n+1"')
            if $<bad_args>;
        make $.node($/)
    }

    method nth_args:sym<odd>($/)     { make {a => 2, b=> 1} }
    method nth_args:sym<even>($/)    { make {a => 2 } }
    method nth_args:sym<expr>($/)    {

        my %node = $.node($/);

        if $<a_sign> {
            %node<a> //= 1;
            %node<a> = -%node<a> if $<a_sign>.Str eq '-';
        }

        if $<b_sign> {
            %node<b> = -%node<b> if $<b_sign>.Str eq '-';
        }

        make %node;
    }
    method nth_functor($/)                   { make $/.Str.lc  }
    method pseudo:sym<nth_child>($/)         { make $.node($/) }

    method negation_args($/) {
        return $.warning('bad :not() argument', $<bad_arg>.Str)
            if $<bad_arg>;
        return $.warning('illegal nested negation', $<nested>.Str)
            if $<nested>;
        make $.list($/);
    }

    method pseudo_function:sym<negation>($/) {
        return $.warning('missing/incorrect arguments to :not()', $<bad_args>.Str)
            if $<bad_args>;
        return unless $<negation_args>.ast;
        make {ident => 'not', args => $<negation_args>.ast}
    }
}

