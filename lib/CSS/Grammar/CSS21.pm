use v6;

use CSS::Grammar;

grammar CSS::Grammar::CSS21 is CSS::Grammar {

# as defined in w3c Appendix G: Grammar of CSS 2.1
# http://www.w3.org/TR/CSS21/grammar.html

    rule TOP {^ <stylesheet> $}

    # productions
    rule stylesheet   { <charset>? <import_etc>* <rule_etc>* }

    rule import_etc   { <import>
                      | $<unexpected>=<charset>
                      }

    rule rule_etc     { <at_rule> | <ruleset>
                      | $<unexpected>=[<charset>|<import>] 
                      | <unknown> }

    rule charset { \@(:i'charset') <charset=string> ';' }
    rule import  { \@(:i'import')  [<string>|<url>] ';' }

    proto rule at_rule { <...> }
    rule at_rule:sym<media>   { \@(:i'media') <media_list> <rulesets> }
    rule at_rule:sym<page>    { \@(:i'page')  <page=pseudo>? <declarations> }

    rule media_list {<medium> [',' <medium>]*}
    rule medium {<ident>}

    rule unary_operator {'-'}

    rule operator {'/'|','}

    rule combinator {'-'|'+'}

    rule ruleset {
        <!after \@> # not an "@" rule
        <selector> [',' <selector>]* <declarations>
    }

    rule property {<ident>}

    rule declarations {
        '{' <declaration> [';' <declaration> ]* ';'? <end_block>
    }

    rule rulesets {
        '{' <ruleset>* <end_block>
    }

    rule end_block {[$<closing_paren>='}' ';'?]?}

    rule declaration {
         <property> ':' [ <expr> <prio>? | <expr_missing> ]
         | <skipped_term>
    }

    rule expr_missing {''}

    rule expr { <unary_operator>? <term_etc>
                    [ <operator>? <term_etc> ]* }

    rule term_etc { <term> | [<!before ')'><skipped_term>] }

    proto rule term {<...>}
    rule term:sym<length>     {<length>}
    rule term:sym<angle>      {<angle>}
    rule term:sym<freq>       {<freq>}
    rule term:sym<percentage> {<percentage>}
    rule term:sym<dimension>  {<dimension>}
    rule term:sym<num>        {<num>}
    rule term:sym<ems>        {:i'em'}
    rule term:sym<exs>        {:i'ex'}
    rule term:sym<hexcolor>   {<id>}
    rule term:sym<url>        {<url>}
    rule term:sym<rgb>        {<rgb>}
    rule term:sym<function>   {<function>}
    rule term:sym<ident>      {<ident>}

    token selector {<simple_selector>[<combinator> <selector>|<ws>[<combinator>? <selector>]?]?}

    token simple_selector { <element_name> [<id> | <class> | <pseudo>]*
                          |                [<id> | <class> | <pseudo>]+ }

    rule pseudo       {':' [<function>|<ident>] }
    token function     {<ident> '(' <expr> ')'}

    # 'lexer' css2 exceptions
}
