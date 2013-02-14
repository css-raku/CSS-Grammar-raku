use v6;

use CSS::Grammar;

grammar CSS::Grammar::CSS21 is CSS::Grammar {

# as defined in w3c Appendix G: Grammar of CSS 2.1
# http://www.w3.org/TR/CSS21/grammar.html

    rule TOP {^ <stylesheet> $}

    # productions
    rule stylesheet   { <charset>?
                        [<import> | <unexpected>]*
                        [<at_rule> | <ruleset> | <unexpected> | <unknown>]* }

    rule charset { \@(:i'charset') <charset=.string> ';' }
    rule import  { \@(:i'import')  [<string>|<url>] ';' }

    rule unexpected {<charset>|<import>}

    proto rule at_rule { <...> }
    rule at_rule:sym<media>   { \@(:i'media') <media_list> <rulesets> }
    rule at_rule:sym<page>    { \@(:i'page')  <page=.pseudo>? <declarations> }

    rule media_list {<medium> [',' <medium>]*}
    rule medium {<ident>}

    rule unary_operator {'-'}
    rule operator {'/'|','}
    rule combinator {'-'|'+'}

    rule ruleset {
        <!after \@> # not an "@" rule
        <selector> <declarations>
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

    rule expr { <term_etc> [ <operator>? <term_etc> ]* }

    rule term_etc { <unary_operator>? <term=.uterm> | <term> | [<!before ')'><skipped_term>] }

    # uterm - able to be prefixed by a unary operator
    proto rule uterm {<...>}
    rule uterm:sym<length>     {<length>}
    rule uterm:sym<angle>      {<angle>}
    rule uterm:sym<freq>       {<freq>}
    rule uterm:sym<percentage> {<percentage>}
    rule uterm:sym<dimension>  {<dimension>}
    rule uterm:sym<num>        {<num>}
    rule uterm:sym<ems>        {:i'em'}
    rule uterm:sym<exs>        {:i'ex'}
    # term - these can't be prefixed by a unary operator
    proto rule term {<...>}
    rule term:sym<string>      {<string>}
    rule term:sym<url>         {<url>}
    rule term:sym<rgb>         {<rgb>}
    rule term:sym<hexcolor>    {<id>}
    rule term:sym<function>    {<function>}
    rule term:sym<ident>       {<ident>}

    # the css2 selector rule make no sense to me ...
    ## token selector {<simple_selector>[<combinator> <selector>|<ws>[<combinator>? <selector>]?]?}
    # ... i've just used the css3 rule
    rule selector {<simple_selector>[[<.ws>?<combinator><.ws>?]? <simple_selector>]* [<.ws>?',']?}

    token simple_selector { <element_name> [<id> | <class> | <pseudo>]*
                          |                [<id> | <class> | <pseudo>]+ }

    rule pseudo       {':' [<function>|<ident>] }
    token function    {<ident> '(' <expr> ')'}

    # 'lexer' css2 exceptions
}
