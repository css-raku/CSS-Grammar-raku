use v6;

use CSS::Grammar;
use CSS::Grammar::CSS21::Properties;
# specification: http://www.w3.org/TR/2008/REC-CSS1-20080411/

grammar CSS::Grammar::CSS1:ver<20080411.000>
    is CSS::Grammar::CSS21::Properties
    is CSS::Grammar {

    rule TOP {^ <stylesheet> $}

    # productions

    rule stylesheet { <import>* [<ruleset> | <misplaced> | <unknown>]* }

    rule import { \@(:i'import') [<string>|<url>] ';' }

    rule misplaced {<import>}

    rule unary_operator {'-'|'+'}

    rule operator {'/'|','}

    rule ruleset {
        <!after \@> # not an "@" rule
        <selectors> <declarations>
    }

    rule selectors { <selector> [',' <selector>]* }

    rule declarations {
        '{' <declaration_list> <.end_block>
    }

    # this rule is suitable for parsing style attributes in HTML documents.
    # see: http://www.w3.org/TR/2010/CR-css-style-attr-20101012/#syntax
    #
    rule declaration_list {[ <declaration> | <dropped_decl> ]*}
    # an unterminated string might have run to end-of-line and consumed ';'

    rule declaration      { $<property>=[<prop>|<unknown_property>] <prio>? <end_decl> }

    rule unknown_property {<property> <expr>}

    rule expr { <term> [ <operator>? <term> ]* }

    rule term { <unary_operator>? <term=.pterm>
              | <.unary_operator>? <term=.aterm> # useless unary operator
              }

    proto rule pterm {*}
    rule pterm:sym<qty>       {<q=.length>|<q=.percentage>}
    rule pterm:sym<num>       {<num>}
    rule pterm:sym<emx>       {<emx>}
    proto rule aterm {*}
    rule aterm:sym<string>    {<string>}
    rule aterm:sym<color>     {<color>}
    rule aterm:sym<url>       {<url>}
    rule aterm:sym<ident>     {<ident>}

    token selector {<simple_selector>[<ws><simple_selector>]* <pseudo>?}

    token simple_selector { <element_name> <id>? <class>? <pseudo>?
                          | <id> <class>? <pseudo>?
                          | <class> <pseudo>?
                          | <pseudo> }

    rule pseudo:sym<element> {':'$<element>=[:i'first-'[line|letter]]}
    # assume anything else is a class
    rule pseudo:sym<class>     {':' <class=.ident> }

    # 'lexer' css1 exceptions:
    # -- css1 identifiers - don't allow '_' or leading '-'
    token nmstrt {(<[a..z A..Z]>)|<nonascii>|<escape>}
    token nmreg  {<[\- a..z A..Z 0..9]>+}
    token ident  {<nmstrt><nmchar>*}
    # -- css1 unicode escape sequences only extend to 4 chars
    rule unicode {'\\'(<[0..9 a..f A..F]>**1..4)}
    # -- css1 extended characters limited to latin1
    token nonascii       {<[\o241..\o377]>}
}
