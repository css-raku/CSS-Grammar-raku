use v6;

use CSS::Grammar;
use CSS::Grammar::CSS21;

# specification: http://www.w3.org/TR/2003/WD-css3-syntax-20030813/

grammar CSS::Grammar::CSS3:ver<20030813.000>
    is CSS::Grammar::CSS21 {

    rule TOP {^ <stylesheet> $}

    # productions
    rule stylesheet { <charset>?
                      [<import>              | <unexpected>]*
                      [<at_rule=.at_decl>    | <unexpected>]*
                      [<at_rule> | <ruleset> | <unexpected2> | <unknown>]* }

    # <at_decl> - at rules preceding main body - aka @namespace extensions
    proto rule at_decl {<...>}

    # to detect out of order directives
    rule unexpected2 {<charset>|<import>|<at_decl>}

    # 'lexer' css3 exceptions
   token nonascii       {<- [\x0..\x7F]>}
}
