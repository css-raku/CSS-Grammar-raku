use v6;

use CSS::Grammar;
# specification: http://www.w3.org/TR/2008/REC-CSS1-20080411/

grammar CSS::Grammar::CSS1:ver<20080411.000>
    is CSS::Grammar {

    rule TOP {^ <stylesheet> $}

    # productions

    rule stylesheet { <import>* [<ruleset> || <misplaced> || <unknown>]* }

    rule import { \@(:i'import') [<string>|<url>] ';' }

    # to detect out of order directives
    rule misplaced {<import>}

    rule ruleset {
        <!after \@> # not an "@" rule
        <selectors> <declarations>
    }

    rule selectors { <selector> [',' <selector>]* }

    rule declarations {
        '{' <declaration-list> <.end-block>
    }

    # this rule is suitable for parsing style attributes in HTML documents.
    # see: http://www.w3.org/TR/2010/CR-css-style-attr-20101012/#syntax
    #
    rule declaration-list { [ <declaration> || <dropped-decl> ]* }

    # delcaration:sym<validated> - extension point for CSS::Language suite
    rule declaration:sym<validated> { <decl> <prio>? <end-decl> }
    rule declaration:sym<raw>       { <property> <expr> <prio>? <end-decl> }
    # css1 syntax allows a unary operator in front of all terms. Throw it
    # out, if the term doesn't consume it.
    rule expr { [<term>||<.unary-op><term>] [ <operator>? [<term>||<.unary-op><term>] ]* }
    rule unary-op       {'+'|'-'}

    token selector {<simple-selector>[<ws><simple-selector>]* <pseudo>?}

    token simple-selector { <element-name> <id>? <class>? <pseudo>?
                          | <id> <class>? <pseudo>?
                          | <class> <pseudo>?
                          | <pseudo> }

    rule pseudo:sym<element> {':'$<element>=[:i'first-'[line|letter]]}
    # assume anything else is a class
    rule pseudo:sym<class>     {':' <class=.ident> }

    # 'lexer' css1 exceptions:
    # -- css1 identifiers - don't allow '_' or leading '-'
    token nmstrt   {(<[a..z A..Z]>)|<nonascii>|<escape>}
    token nmreg    {<[\- a..z A..Z 0..9]>+}
    token ident-cs {<nmstrt><nmchar>*}
    # -- css1 unicode escape sequences only extend to 4 chars
    rule unicode {'\\'(<[0..9 a..f A..F]>**1..4)}
    # -- css1 extended characters limited to latin1
    token nonascii       {<[\o241..\o377]>}
}
