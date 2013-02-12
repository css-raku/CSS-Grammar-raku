use v6;

use CSS::Grammar;

grammar CSS::Grammar::CSS1 is CSS::Grammar {

# as defined in w3c Appendix B: CSS1 Grammar
# http://www.w3.org/TR/REC-CSS1/#appendix-b

    rule TOP {^ <stylesheet> $}

    # productions

    rule stylesheet { <import>* <rule_etc>* }
    rule rule_etc   { <ruleset>
                    | <unexpected=import>
                    | <unknown> }

    rule import { \@(:i'import') [<string>|<url>] ';' }

    rule unary_operator {'-'|'+'}

    rule operator {'/'|','}

    rule ruleset {
        <!after \@> # not an "@" rule
        <selector> [',' <selector>]* <declarations>
    }

    rule property {<ident>}

    rule declarations {
        '{' <declaration> [';' <declaration> ]* ';'? <end_block>
    }

    rule end_block {[$<closing_paren>='}' ';'?]?}

    rule declaration {
        <property> ':' [ <expr> <prio>? | <expr_missing> ]
        | <skipped_term>
    }

    rule expr { <term_etc> [ <operator>? <term_etc> ]* }

    rule expr_missing {''}

    rule term_etc { <unary_operator>? [ <term=.uterm> | <term> | <skipped_term> ] }

    proto rule uterm {<...>}
    rule uterm:sym<length>     {<length>}
    rule uterm:sym<percentage> {<percentage>}
    rule uterm:sym<num>        {<num>}
    rule uterm:sym<ems>        {:i'em'}
    rule uterm:sym<exs>        {:i'ex'}
    proto rule term {<...>}
    rule term:sym<hexcolor>    {<id>}
    rule term:sym<rgb>         {<rgb>}
    rule term:sym<url>         {<url>}
    rule term:sym<ident>       {<ident>}

    token selector {<simple_selector>[<ws><simple_selector>]* <pseudo_element_etc>?}

    token simple_selector { <element_name> <id>? <class>? <pseudo_class_etc>?
                          | <id> <class>? <pseudo_class_etc>?
                          | <class> <pseudo_class_etc>?
                          | <pseudo_class_etc> }

    rule pseudo_class   {':'(:i link|visited|active)}
    rule pseudo_element {':'(:i first\-[line|letter])}
    rule pseudo         {':'<ident>}

    rule pseudo_class_etc   {<pseudo_class>|<pseudo>}
    rule pseudo_element_etc {<pseudo_element>|<pseudo>}

    # 'lexer' css1 exceptions

    # css1 identifiers - don't allow '_' or leading '-'
    token nmstrt         {(<[a..z A..Z]>)|<nonascii>|<escape>}
    token nmchar         {(<[\- a..z A..Z 0..9]>)|<nonascii>|<escape>}
    token ident          {<nmstrt><nmchar>*}
    # -- css1 unicode escape sequences only extend to 4 chars
    rule unicode {'\\'(<[0..9 a..f A..F]>**1..4)}
}
