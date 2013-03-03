use v6;

use CSS::Grammar;
use CSS::Grammar::CSS3::Module::Colors;
use CSS::Grammar::CSS3::Module::Selectors;

# specification: http://www.w3.org/TR/2003/WD-css3-syntax-20030813/

grammar CSS::Grammar::CSS3:ver<20030813.000>
    is CSS::Grammar::CSS3::Module::Colors
    is CSS::Grammar::CSS3::Module::Selectors
    is CSS::Grammar {

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

    rule media_list {<medium> [',' <medium>]*}
    rule medium {<ident>}

    rule unary_operator {'-'|'+'}
    rule operator {'/'|','}

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
    rule pterm:sym<emx>           {<emx>}
    # aterm - atomic; these can't be prefixed by a unary operator
    proto rule aterm {<...>}
    rule aterm:sym<string>        {<string>}
    rule aterm:sym<url>           {<url>}
    rule aterm:sym<function>      {<function>}
    rule aterm:sym<unicode_range> {<unicode_range>}
    rule aterm:sym<ident>         {<!before emx><ident>}

    token function    {<ident> '(' <expr>? [')' | <unclosed_paren>]}

    rule unicode_range {:i'U+'<range>}
    proto rule range { <...> }
    rule range:sym<from_to> {$<from>=[<xdigit> ** 1..6] '-' $<to>=[<xdigit> ** 1..6]}
    rule range:sym<masked>  {[<xdigit>|'?'] ** 1..6}

    # 'lexer' css3 exceptions
}
