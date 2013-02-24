use v6;

use CSS::Grammar;

grammar CSS::Grammar::CSS1 is CSS::Grammar {

# as defined in w3c Appendix B: CSS1 Grammar
# http://www.w3.org/TR/REC-CSS1/#appendix-b

    rule TOP {^ <stylesheet> $}

    # productions

    rule stylesheet { <import>* [<ruleset> | <unexpected> | <unknown>]* }

    rule import { \@(:i'import') [<string>|<url>] ';' }

    rule unexpected {<import>}

    rule unary_operator {'-'|'+'}

    rule operator {'/'|','}

    rule ruleset {
        <!after \@> # not an "@" rule
        <selectors> <declarations>
    }

    rule selectors {
        <selector> [',' <selector>]*
    }

    rule declarations {
        '{' <declaration> [';' <declaration> ]* ';'? <end_block>
    }

    rule end_block {[$<closing_paren>='}' ';'?]?}

    rule property {<ident>}

    rule declaration {
        <property> ':' [ <expr> <prio>? | <expr_missing> ]
        | <skipped_term>
    }

    rule expr { <term> [ <operator>? <term> ]* }

    rule expr_missing {''}

    rule term { <unary_operator>? [ <term=.pterm> | <term=.aterm> | <!before <[\!]>><skipped_term> ] }

    proto rule pterm {<...>}
    rule pterm:sym<length>     {<length>}
    rule pterm:sym<percentage> {<percentage>}
    rule pterm:sym<num>        {<num>}
    rule pterm:sym<ems>        {:i'em'}
    rule pterm:sym<exs>        {:i'ex'}
    proto rule aterm {<...>}
    rule aterm:sym<string>     {<string>}
    rule aterm:sym<color_hex>  {<id>}
    rule aterm:sym<color_rgb>  {<color_rgb>}
    rule aterm:sym<url>        {<url>}
    rule aterm:sym<ident>      {<ident>}

    token selector {<simple_selector>[<ws><simple_selector>]* <pseudo>?}

    token simple_selector { <element_name> <id>? <class>? <pseudo>?
                          | <id> <class>? <pseudo>?
                          | <class> <pseudo>?
                          | <pseudo> }

    rule pseudo  {':'<ident=.pseudo_ident>}

    # 'lexer' css1 exceptions:
    # -- css1 identifiers - don't allow '_' or leading '-'
    token nmstrt {(<[a..z A..Z]>)|<nonascii>|<escape>}
    token nmchar {(<[\- a..z A..Z 0..9]>)|<nonascii>|<escape>}
    token ident  {<nmstrt><nmchar>*}
    # -- css1 unicode escape sequences only extend to 4 chars
    rule unicode {'\\'(<[0..9 a..f A..F]>**1..4)}
    # -- css1 extended characters limited to latin1
    token nonascii       {<[\o241..\o377]>}
    token escape         {<unicode>|'\\'$<char>=[<regascii>|<nonascii>]}
}
