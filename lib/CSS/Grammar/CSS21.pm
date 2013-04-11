use v6;

use CSS::Grammar;
# specification: http://www.w3.org/TR/2011/REC-CSS2-20110607/

grammar CSS::Grammar::CSS21:ver<20110607.001>
    is CSS::Grammar {

    rule TOP {^ <stylesheet> $}

    # productions
    rule stylesheet { <charset>?
                      [<import> || <misplaced>]*
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

    # inherited combinators: '+' (adjacent)
    token combinator:sym<not> {'-'}

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
    rule declaration_list { [ <declaration> || <dropped_decl> ]* }
    # an unterminated string might have run to end-of-line and consumed ';'

    rule declaration:sym<validated> { <decl> <prio>? <end_decl> }
    rule declaration:sym<raw>       { <property> <expr> <prio>? <end_decl> }

    rule expr { <term> [ <operator>? <term> ]* }

    # quantity inherited from base grammar: length, percentage
    token angle               {:i<num>(deg|rad|grad)}
    token quantity:sym<angle> {<angle>}

    token time                {:i<num>(m?s)}
    token quantity:sym<time>  {<time>}

    token freq                {:i<num>(k?Hz)}
    token quantity:sym<freq>  {<freq>}

    rule term:sym<function>  {<function>|<function=.any_function>}

    rule selector{<simple_selector>[[<.ws>?<combinator><.ws>?]? <simple_selector>]*}

    token simple_selector { <element_name> [<id> | <class> | <attrib> | <pseudo>]*
                          |                [<id> | <class> | <attrib> | <pseudo>]+ }

    rule attrib  {'[' <ident> [ <attribute_selector> [<ident>|<string>] ]? ']'}

    proto token attribute_selector {*}
    token attribute_selector:sym<equals>   {'='}
    token attribute_selector:sym<includes> {'~='}
    token attribute_selector:sym<dash>     {'|='}

    rule pseudo:sym<element> {':'$<element>=[:i'first-'[line|letter]|before|after]}
    rule pseudo:sym<function> {':'[<function=.pseudo_function>||<unknown_pseudo_func>]}
    # assume anything else is a class
    rule pseudo:sym<class>     {':' <class=.ident> }

    proto rule function { <...> }
    token any_function      {<ident>'(' [<args=.expr>||<args=.any_arg>]* ')'}

    proto rule pseudo_function { <...> }
    rule pseudo_function:sym<lang> {:i'lang(' [ <ident> || <any_args> ] ')'}
    # pseudo function catch-all
    rule unknown_pseudo_func   {<ident>'(' [<args=.expr>||<args=.any_arg>]* ')'}

    # 'lexer' css2 exceptions
    # non-ascii limited to single byte characters
    token nonascii            {<[\o240..\o377]>}
}

