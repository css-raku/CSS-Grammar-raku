use v6;

use CSS::Grammar::CSS1;
# specification: http://www.w3.org/TR/2011/REC-CSS2-20110607/

grammar CSS::Grammar::CSS21:ver<20110607.001>
    is CSS::Grammar::CSS1 {

    rule TOP {^ <stylesheet> $}

    # productions
    rule stylesheet { <charset>?
                      [<import> | <misplaced>]*
                      ['@'<at_rule> | <ruleset> || <misplaced> || <unknown>]* }

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

    rule term { <unary_operator>? <term=.pterm> | <term=aterm> } 

    # units inherited from base grammar: length, percentage
    token angle            {:i<num>(deg|rad|grad)}
    token units:sym<angle> {<angle>}

    token time             {:i<num>(m?s)}
    token units:sym<time>  {<time>}

    token freq             {:i<num>(k?Hz)}
    token units:sym<freq>  {<freq>}

    # aterm - atomic; these can't be prefixed by a unary operator
    rule aterm:sym<function>  {<function>|<unknown_function>}

    rule selector{<simple_selector>[[<.ws>?<combinator><.ws>?]? <simple_selector>]*}

    token simple_selector { <element_name> [<id> | <class> | <attrib> | <pseudo>]*
                          |                [<id> | <class> | <attrib> | <pseudo>]+ }

    rule attrib  {'[' <ident> [ <attribute_selector> [<ident>|<string>] ]? ']'}

    proto token attribute_selector {*}
    token attribute_selector:sym<equals>   {'='}
    token attribute_selector:sym<includes> {'~='}
    token attribute_selector:sym<dash>     {'|='}

    rule pseudo:sym<element> {':'$<element>=[:i'first-'[line|letter]|before|after]}
    rule pseudo:sym<function> {':'[<function=.pseudo_function>|<unknown_pseudo_func>]}
    # assume anything else is a class
    rule pseudo:sym<class>     {':' <class=.ident> }

    # distinguish regular functions from psuedo_functions

    proto rule function { <...> }
    # I haven't found a good list of css2.1 functions; there's probably more
    rule function:sym<attr>     {:i'attr(' [ <attribute_name=.ident> <type_or_unit=.ident>? [ ',' <fallback=.ident> ]? || <bad_args>] ')'}
    rule function:sym<counter>  {:i'counter(' [ <ident> [ ',' <ident> ]* || <bad_args> ] ')'}
    rule function:sym<counters> {:i'counters(' [ <ident> [ ',' <string> ]? || <bad_args> ] ')' }
    # catch alls for unknown function names and arguments. individual
    # declarations should ideally catch bad argument lists and give
    # friendlier function-specific messages
    token unknown_function      {<ident>'(' [<args=.expr>|<args=.bad_arg>]* ')'}

    proto rule pseudo_function { <...> }
    rule pseudo_function:sym<lang> {:i'lang(' [ <ident> || <bad_args> ] ')'}
    # pseudo function catch-all
    rule unknown_pseudo_func   {<ident>'(' [<args=.expr>|<args=.bad_arg>]* ')'}

    # core grammar extensions
    # non-ascii limited to single byte characters
    # nonascii is ... anything but ascii
    token nonascii            {<[\o240..\o377]>}
    # allow underscores in identifiers
    token nmstrt         {(<[_ a..z A..Z]>)|<nonascii>|<escape>}
    token nmreg          {<[_ \- a..z A..Z 0..9]>+}
    token ident          {$<pfx>=['-']?<nmstrt><nmchar>*}
    token unicode        {'\\'(<[0..9 a..f A..F]>**1..6)}
}
