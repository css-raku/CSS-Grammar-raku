use v6;

grammar CSS::Grammar::Scan{...}

grammar CSS::Grammar:ver<0.0.1> {

    # abstract base grammar for CSS instance grammars:
    #  CSS::Grammar::CSS1  - CSS level 1
    #  CSS::Grammar::CSS21 - CSS level 2.1
    #  CSS::Grammar::CSS3  - CSS level 3

    # Comments and whitespace

    token nl {"\n"|"\r\n"|"\r"|"\f"}

    # comments: nb trigger <nl> for accurate line counting
    token comment {('<!--') [<nl>|.]*? ['-->' | <unclosed_comment>]
                  |('/*')  [<nl>|.]*?  ['*/'  | <unclosed_comment>]}
    token unclosed_comment {$}

    token wc {<nl> | "\t"  | " "}
    token ws {<!ww>[<wc>|<comment>]*}

    # "lexer"com
    # taken from http://www.w3.org/TR/css3-syntax/ 11.2 Lexical Scanner

    token unicode        {'\\'(<[0..9 a..f A..F]>**1..6)}
    # w3c nonascii :== #x80-#xD7FF #xE000-#xFFFD #x10000-#x10FFFF
    token regascii       {<[\x20..\x7F]>}
    token nonascii       {<- [\x0..\x7F]>}
    token escape         {<unicode>|'\\'$<char>=[<regascii>|<nonascii>]}
    token nmstrt         {(<[_ a..z A..Z]>)|<nonascii>|<escape>}
    token nmchar         {<nmreg>|<nonascii>|<escape>}
    token nmreg          {<[_ \- a..z A..Z 0..9]>+}
    token ident          {$<pfx>=['-']?<nmstrt><nmchar>*}
    token name           {<nmchar>+}
    token num            {[\d* \.]? \d+}
    token posint         {\d+}

    proto token stringchar {*}
    token stringchar:sym<cont>      {\\<nl>}
    token stringchar:sym<escape>    {<escape>}
    token stringchar:sym<nonascii>  {<nonascii>}
    token stringchar:sym<ascii>     {<[\o40 \! \# \$ \% \& \(..\[ \]..\~]>+}

    token single_quote   {\'}
    token double_quote   {\"}
    token string         {\"[<stringchar>|<stringchar=.single_quote>]*\"
                         |\'[<stringchar>|<stringchar=.double_quote>]*\'
    }
    token id             {'#'<name>}
    token class          {'.'<name>}
    token element_name   {<ident>}

    proto token units {*}
    token units:sym<length>     {:i[pt|mm|cm|pc|in|px|em|ex]}
    token units:sym<percentage> {'%'}

    token url_delim_char {\( | \) | \' | \" | \\ | <wc>}
    token url_char       {<escape>|<nonascii>|<- url_delim_char>+}
    token url_string     {<string>|<url_char>*}

    # productions

    rule url  {:i'url(' <url_string> ')' }
    token unclosed_paren {''}

    rule emx {:i e[m|x]}

    rule color_arg{<num>$<percentage>=[\%]?}

    proto rule color    {*}
    rule color:sym<rgb> {:i'rgb('
                   [$<ok>=[<r=.color_arg> ','
                          <g=.color_arg> ','
                          <b=.color_arg>] | <any>*]
                   ')'
    }
    rule color:sym<hex> {<id>}

    token prio {:i'!' [('important')|<any>] }

    # pseudos
    proto rule pseudo {*}
    rule pseudo:sym<element> {':' $<element>=[:i'first-'[line|letter]|before|after]}

    # Combinators - introduced with css2.1
    proto token combinator {*}
    token combinator:sym<adjacent> {'+'}
    token combinator:sym<child>    {'>'}

    # Unicode ranges - used by selector modules + scan rules
    proto rule unicode_range {*}
    rule unicode_range:sym<from_to> {$<from>=[<xdigit> ** 1..6] '-' $<to>=[<xdigit> ** 1..6]}
    rule unicode_range:sym<masked>  {[<xdigit>|'?'] ** 1..6}

    rule property {<property=.ident> ':'}
    rule end_decl { ';' | <?before '}'> | $ }

    # Error Recovery
    # --------------
    # <any> - for bad function arguments etc
    rule any       { <CSS::Grammar::Scan::_value>}
    rule badstring {<CSS::Grammar::Scan::_badstring>}

    # failed declaration parse - how well formulated is it?
    proto rule dropped_decl { <...> }
    # - parsed a property; some terms are unknown
    rule dropped_decl:sym<forward_compat> { <property> [<expr>|(<any>)]* <end_decl> }
    # - couldn't get a property, but terms well formed
    rule dropped_decl:sym<stray_terms>    { (<any>+) <end_decl> }
    # - unterminated string. might consume ';' '}' and other constructs
    rule dropped_decl:sym<badstring>      { <property>? (<any>)*? <.badstring> <end_decl>? }
    # - unable to parse it at all; throw it out
    rule dropped_decl:sym<flushed>        { ( <any> | <- [\;\}]> )+ <end_decl> }


    # forward compatible scanning and recovery - from the stylesheet top level
    proto token unknown {*}
    # - try to skip whole statements or at-rules
    token unknown:sym<statement>   { <CSS::Grammar::Scan::_statement> }
    # - if that failed, start skipping intermediate tokens
    token unknown:sym<flushed>     { <any>+ }
    token unknown:sym<badstring>   { <badstring> } 
    token unknown:sym<punct>       { <punct> }
    # - last resort skip a character; let parser try again
    token unknown:sym<char>        {<[.]>}
}


grammar CSS::Grammar::Scan is CSS::Grammar {

    # Fallback Grammar Only!!
    # This grammar is based on the universal grammar syntax described in
    # http://www.w3.org/TR/2011/REC-CSS2-20110607/syndata.html#syntax
    # It is a scanning grammar that is only used to implement term flushing
    # for forward compatiblity and/or ignoring unknown constructs

    # It's been generalized to handle the rule dropping requirements outlined
    # in http://www.w3.org/TR/2003/WD-css3-syntax-20030813/#rule-sets
    # e.g this should be complety dropped: h3, h4 & h5 {color: red }
    # Errata:
    # - declarations are less structured - optimized for robsutness
    # - added <op> for general purpose operator detection
    # - may assume closing parenthesis in nested values and blocks

    rule TOP           {^ <_stylesheet> $}
    rule _stylesheet   {<_statement>*}
    rule _statement    {<_ruleset> | '@'<_at_rule>}

    rule _at_keyword   {\@<ident>}
    rule _at_rule      {(<ident>) <_any>* [<_block> | <_badstring> | ';']}
    rule _block        {'{' [ <_value> | <_badstring> | ';' ]* '}'?}

    rule _ruleset      { <_selectors>? <_declarations> }
    rule _selectors    { [<_any> | <_badstring>]+ }
    rule _declarations {'{' <_declaration_list> '}' ';'?}
    rule _declaration_list {[<property> | <_value> | <_badstring> |';']*}
    rule _value        {[ <_any> | <_block> | <_at_keyword> ]+}

    token _delim       {<[\( \) \{ \} \; \" \' \\]>}
    token _op          {[<punct><!after <_delim>>]+}

    token _badstring   {\"[<stringchar>|<stringchar=.single_quote>]*[<nl>|$]
                       |\'[<stringchar>|<stringchar=.double_quote>]*[<nl>|$]}

    proto rule _any { <...> }
    rule _any:sym<string> { <string> }
    rule _any:sym<num>    { <num>['%'|<dimension=.ident>]? }
    rule _any:sym<urange> { 'U+'<unicode_range> }
    rule _any:sym<ident>  { <ident> }
    rule _any:sym<pseudo> { <pseudo> }
    rule _any:sym<id>     { <id> }
    rule _any:sym<class>  { <class> }
    rule _any:sym<op>     { <_op> }
    rule _any:sym<attrib> { '[' [ <_any> | <_unused> ]* [']' | <unclosed_paren>] }
    rule _any:sym<args>   { '(' [ <_any> | <_unused> ]* [')' | <unclosed_paren>] }

    rule _unused { <_block> | <_at_keyword> }
}
