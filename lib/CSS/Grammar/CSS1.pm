use v6;

use CSS::Grammar;

grammar CSS::Grammar::CSS1 is CSS::Grammar {

# as defined in w3c Appendix B: CSS1 Grammar
# http://www.w3.org/TR/REC-CSS1/#appendix-b

    rule TOP {^ <stylesheet> $}

    # comb; rule to reduce a css2+ or hand-coded stylesheet to a cleaner,
    # css1 parseable subset:
    # my $css1 = $css_input.comb(/<CSS::Grammar::CSS1::comb>/)

    rule comb { <import> | <ruleset> }

    # productions

    rule stylesheet { <import>* <rule_etc>* }
    rule rule_etc  { <ruleset> | <late=import> }

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
        <property> ':' [<expr> <prio>?]?
    }

    rule expr { <unary_operator>? <term_etc>
                    [ <operator>? <term_etc> ]* }

    rule term_etc { <term> | <skipped_term> }

    proto rule term {<...>}
    rule term:sym<length>     {<length>}
    rule term:sym<percentage> {<percentage>}
    rule term:sym<dimension>  {<dimension>}
    rule term:sym<num>        {<num>}
    rule term:sym<ems>        {:i'em'}
    rule term:sym<exs>        {:i'ex'}
    rule term:sym<hexcolor>   {<id>}
    rule term:sym<rgb>        {<rgb>}
    rule term:sym<url>        {<url>}
    rule term:sym<ident>      {<ident>}

    token selector {<simple_selector>[<ws><simple_selector>]* <pseudo_element_etc>?}

    token simple_selector { <element_name> <id>? <class>? <pseudo_class_etc>?
                          | <id> <class>? <pseudo_class_etc>?
                          | <class> <pseudo_class_etc>?
                          | <pseudo_class_etc> }

    rule pseudo {<pseudo_class> | <pseudo_element> | <pseudo_other>}
    rule pseudo_class   {':'(:i link|visited|active)}
    rule pseudo_element {':'(:i first\-[line|letter])}
    rule pseudo_skipped {':'<ident>}

    rule pseudo_class_etc   {<pseudo_class>|<pseudo_skipped>}
    rule pseudo_element_etc {<pseudo_element>|<pseudo_skipped>}

    # 'lexer' css1 exceptions
    
    # -- css1 unicode escape sequences only extend to 4 chars
    rule unicode {'\\'(<[0..9 a..f A..F]>**1..4)}
}
