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
    rule at_rule:sym<page>     { \@(:i'page')  <page=.pseudo>? <declarations> }

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

    rule term { <unary_operator>? <term=.uterm> | <term=_term> | [<!before <[\!\)]>><skipped_term>] }

    # uterm - able to be prefixed by a unary operator
    proto rule uterm {<...>}
    rule uterm:sym<length>        {<length>}
    rule uterm:sym<angle>         {<angle>}
    rule uterm:sym<freq>          {<freq>}
    rule uterm:sym<percentage>    {<percentage>}
    rule uterm:sym<dimension>     {<dimension>}
    rule uterm:sym<num>           {<num>}
    rule uterm:sym<ems>           {:i'em'}
    rule uterm:sym<exs>           {:i'ex'}
    # _term - these can't be prefixed by a unary operator
    proto rule _term {<...>}
    rule _term:sym<string>        {<string>}
    rule _term:sym<url>           {<url>}
    rule _term:sym<rgb>           {<rgb>}
    rule _term:sym<hexcolor>      {<id>}
    rule _term:sym<function>      {<function>}
    rule _term:sym<unicode_range> {<unicode_range>}
    rule _term:sym<ident>         {<ident>}

    rule unicode_range {:i'U+'<range>}
    proto rule range { <...> }
    rule range:sym<from_to> {$<from>=[<xdigit> ** 1..6] '-' $<to>=[<xdigit> ** 1..6]}
    rule range:sym<masked>  {[<xdigit>|'?'] ** 1..6}

    rule selector {<simple_selector>[[<.ws>?<combinator><.ws>?]? <simple_selector>]*}

    token simple_selector { <element_name> [<id> | <class> | <attrib> | <pseudo>]*
                          |                [<id> | <class> | <attrib> | <pseudo>]+ }

    rule attrib       {'[' <ident> [ <match> [<ident>|<string>] ]? ']'}

    proto rule match {<...>}
    rule match:sym<equals>    {'='}
    rule match:sym<includes>  {'~='}
    rule match:sym<dash>      {'|='}
    rule match:sym<prefix>    {'^='}
    rule match:sym<suffix>    {'$='}
    rule match:sym<substring> {'*='}

    rule pseudo       {':' [<function>|<ident>] }
    token function    {<ident> '(' <expr> ')'}

    # 'lexer' css3 exceptions
}
