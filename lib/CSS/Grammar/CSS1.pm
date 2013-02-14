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
        <selector> <declarations>
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
    rule term:sym<string>      {<string>}
    rule term:sym<hexcolor>    {<id>}
    rule term:sym<rgb>         {<rgb>}
    rule term:sym<url>         {<url>}
    rule term:sym<ident>       {<ident>}

    token selector {<simple_selector>[<ws><simple_selector>]* <pseudo>? [<.ws>?',']?}

    token simple_selector { <element_name> <id>? <class>? <pseudo>?
                          | <id> <class>? <pseudo>?
                          | <class> <pseudo>?
                          | <pseudo> }

    rule pseudo  {':'<ident>}

    # 'lexer' css1 exceptions:
    # -- css1 identifiers - don't allow '_' or leading '-'
    token nmstrt {(<[a..z A..Z]>)|<nonascii>|<escape>}
    token nmchar {(<[\- a..z A..Z 0..9]>)|<nonascii>|<escape>}
    token ident  {<nmstrt><nmchar>*}
    # -- css1 unicode escape sequences only extend to 4 chars
    rule unicode {'\\'(<[0..9 a..f A..F]>**1..4)}
}
