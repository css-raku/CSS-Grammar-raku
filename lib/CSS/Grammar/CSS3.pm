use v6;
use CSS::Grammar;

grammar CSS::Grammar::CSS3 is CSS::Grammar {

# core CSS3 Grammar - no extensions yet
# as defined in w3c Appendix G: Grammar of CSS 2.1
# http://www.w3.org/TR/CSS21/grammar.html

    rule TOP {^ <stylesheet> $}

    # productions
    rule stylesheet { <charset>?
                      [<import>              | <unexpected>]*
                      [<namespace>           | <unexpected>]*
                      [<at_rule> | <ruleset> | <unexpected2> | <unknown>]* }

    rule charset { \@(:i'charset') <string> ';' }
    rule import  { \@(:i'import')  [<string>|<url>] ';' }

    rule namespace { \@(:i'namespace') <ident>? [<string>|<url>] ';' }

    # to detect out of order directives
    rule unexpected  {<charset>|<import>}
    rule unexpected2 {<charset>|<import>|<namespace>}

    proto rule at_rule { <...> }
    rule at_rule:sym<media>    { \@(:i'media') <media_list> <rulesets> }
    # todo: factor into Page css3 module?
    rule at_rule:sym<page>     { \@(:i'page')  <page=.pseudo>? <declarations> }
    token pseudo_keyw:sym<page> {:i(left|right|first)}

    rule media_list {<medium> [',' <medium>]*}
    rule medium {<ident>}

    rule unary_operator {'-'|'+'}
    rule operator {'/'|','}
    rule combinator {'+'|'>'}

    rule ruleset {
        <!after \@> # not an "@" rule
        <selectors> <declarations>
    }

    rule declarations {
        '{' <declaration> [';' <declaration> ]* ';'? <end_block>
    }

    rule rulesets {
        '{' <ruleset>* <end_block>
    }

    rule selectors {
        <selector> [',' <selector>]*
    }

    rule end_block {[$<closing_paren>='}' ';'?]?}

    rule property {<ident>}

    rule declaration {
         <property> ':' [ <expr> <prio>? | <expr_missing> ]
         | <skipped_term>
    }

    rule expr_missing {''}

    rule expr { <term> [ <operator>? <term> ]* }

    rule term { <unary_operator>? <term=.pterm> | <term=.aterm> | [<!before <[\!\)]>><skipped_term>] }

    # pterm - able to be prefixed by a unary operator
    proto rule pterm {<...>}
    rule pterm:sym<length>        {<length>}
    rule pterm:sym<angle>         {<angle>}
    rule pterm:sym<time>          {<time>}
    rule pterm:sym<freq>          {<freq>}
    rule pterm:sym<percentage>    {<percentage>}
    rule pterm:sym<dimension>     {<dimension>}
    rule pterm:sym<num>           {<num>}
    rule pterm:sym<ems>           {:i'em'}
    rule pterm:sym<exs>           {:i'ex'}
    # aterm - atomic; these can't be prefixed by a unary operator
    proto rule aterm {<...>}
    rule aterm:sym<string>        {<string>}
    rule aterm:sym<url>           {<url>}
    rule aterm:sym<function>      {<function>}
    rule aterm:sym<unicode_range> {<unicode_range>}
    rule aterm:sym<ident>         {<ident>}

    rule unicode_range {:i'U+'<range>}
    proto rule range { <...> }
    rule range:sym<from_to> {$<from>=[<xdigit> ** 1..6] '-' $<to>=[<xdigit> ** 1..6]}
    rule range:sym<masked>  {[<xdigit>|'?'] ** 1..6}

    rule selector {<simple_selector>[[<.ws>?<combinator><.ws>?]? <simple_selector>]*}

    token simple_selector { <element_name> [<id> | <class> | <attrib> | <pseudo>]*
                          |                [<id> | <class> | <attrib> | <pseudo>]+ }

    

    rule attrib       {'[' <ident> [ <attribute_selector> [<ident>|<string>] ]? ']'}

    # CSS3 introduces some new attribute selectors
    # Todo: factor into css3 Selectors module
    rule attribute_selector:sym<prefix>    {'^='}
    rule attribute_selector:sym<suffix>    {'$='}
    rule attribute_selector:sym<substring> {'*='}

    rule pseudo       {':' [<function>|<ident=.pseudo_ident>] }
    token function    {<ident> '(' <expr> [')' | <unclosed_paren>]}

    token pseudo_keyw:sym<element> {:i(first\-[line|letter]|before|after)}
    token pseudo_keyw:sym<dclass> {:i(hover|active|focus)}
    token pseudo_keyw:sym<lang> {:i(lang)}

    # 'lexer' css3 exceptions
}
