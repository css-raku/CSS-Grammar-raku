use v6;

use CSS::Grammar;
# specification: http://www.w3.org/TR/2011/REC-CSS2-20110607/

grammar CSS::Grammar::CSS21:ver<20110607.000> is CSS::Grammar {

    rule TOP {^ <stylesheet> $}

    # productions
    rule stylesheet { <charset>?
                      [<import> | <misplaced>]*
                      ['@'<at_rule> | <ruleset> | <misplaced> | <unknown>]* }

    rule charset { \@(:i'charset') <string> ';' }
    rule import  { \@(:i'import')  [<string>|<url>] <media_list>? ';' }
    # to detect out of order directives
    rule misplaced {<charset>|<import>}

    proto rule at_rule {*}

    rule at_rule:sym<media>   {(:i'media') <media_list> <media_rules> }
    rule media_list           {<media_query> [',' <media_query>]*}
    rule media_query          {<media=.ident>}
    rule media_rules          {'{' <ruleset>* <.end_block>}

    rule at_rule:sym<page>    {(:i'page')  <page=.page_pseudo>? <declarations> }
    rule page_pseudo          {':'<ident>}

    rule unary_operator       {'+'|'-'}
    rule operator             {'/'|','}

    # inherited combinators: '+' (adjacent)
    token combinator:sym<not> {'-'}

    rule ruleset {
        <!after \@> # not an "@" rule
        <selectors> <declarations>
    }

    rule declarations {
        '{' <declaration_list> <.end_block>
    }

    # this rule is suitable for parsing style attributes in HTML documents.
    # see: http://www.w3.org/TR/2010/CR-css-style-attr-20101012/#syntax
    #
    rule declaration_list {[ <declaration> | <dropped_decl> ]*}

    rule selectors { <selector> [',' <selector>]* }

    rule declaration   {<property> <expr> <prio>? <end_decl> }

    rule expr { <term> [ <operator>? <term> ]* }

    rule term { <unary_operator>? <term=.pterm> | <term=aterm> } 

    # units inherited from base grammar: length, percentage
    token units:sym<angle>    {:i[deg|rad|grad]}
    token units:sym<time>     {:i[m?s]}
    token units:sym<freq>     {:i[k?Hz]}

    # pterm - able to be prefixed by a unary operator
    proto rule pterm {*}
    rule pterm:sym<quantity>  {<num><units>?}
    rule pterm:sym<emx>       {<emx>}
    # aterm - atomic; these can't be prefixed by a unary operator
    proto rule aterm {*}
    rule aterm:sym<string>    {<string>}
    rule aterm:sym<url>       {<url>}
    rule aterm:sym<color>     {<color>}
    rule aterm:sym<function>  {<function>|<unknown_function>}
    rule aterm:sym<ident>     {<ident>}

    rule selector{<simple_selector>[[<.ws>?<combinator><.ws>?]? <simple_selector>]*}

    token simple_selector { <element_name> [<id> | <class> | <attrib> | <pseudo>]*
                          |                [<id> | <class> | <attrib> | <pseudo>]+ }

    rule attrib  {'[' <ident> [ <attribute_selector> [<ident>|<string>] ]? ']'}

    proto token attribute_selector {*}
    token attribute_selector:sym<equals>   {'='}
    token attribute_selector:sym<includes> {'~='}
    token attribute_selector:sym<dash>     {'|='}

    # pseudo:sym<elem> inherited from base 
    rule pseudo:sym<function> {':'[<function=.pseudo_function>|<unknown_pseudo_func>]}

    # assume anything else is a class
    rule pseudo:sym<class>    {':' <class=.ident> }

    # distinguish regular functions from psuedo_functions

    proto rule function { <...> }
    # I haven't found a good list of css2.1 functions; there's probably more
    rule function:sym<attr>     {:i'attr(' [ <attribute_name=.ident> <type_or_unit=.ident>? [ ',' <fallback=.ident> ]? ')' | <any_arg>* ')' ] }
    rule function:sym<counter>  {:i'counter(' [ <ident> [ ',' <ident> ]* ')' | <any_arg>* ')'] }
    rule function:sym<counters> {:i'counters(' [ <ident> [ ',' <string> ]? ')' | <any_arg>* ')' ] }
    # catch alls for unknown function names and arguments. individual
    # declarations should ideally catch bad argument lists and give
    # friendlier function-specific messages
    token unknown_function      {<ident>'(' [<args=.expr>|<args=.any_arg>]*  ')' }

    proto rule pseudo_function { <...> }
    rule pseudo_function:sym<lang> {:i'lang(' [ <ident> ')' | <any_arg>* ')']}
    # pseudo function catch-all
    rule unknown_pseudo_func       {<ident>'(' [<args=.expr>|<args=.any_arg>]* ')'}

    # 'lexer' css2 exceptions
    # non-ascii limited to single byte characters
    token nonascii            {<[\o240..\o377]>}
}
