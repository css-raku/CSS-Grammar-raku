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
    token int            {['+'|'-']?\d+}

    proto token stringchar {*}
    token stringchar:sym<cont>      {\\<nl>}
    token stringchar:sym<escape>    {<escape>}
    token stringchar:sym<nonascii>  {<nonascii>}
    token stringchar:sym<ascii>     {<[\o40 \! \# \$ \% \& \(..\[ \]..\~]>+}

    token single_quote   {\'}
    token double_quote   {\"}
    token string         {\"[<stringchar>|<stringchar=.single_quote>]*$<closing_quote>=\"?
                         |\'[<stringchar>|<stringchar=.double_quote>]*$<closing_quote>=\'?}

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

    rule url  {:i'url(' <url_string> [')' | <unclosed_paren>] }
    token unclosed_paren {''}

    rule emx {:i e[m|x]}

    rule color_arg{<num>$<percentage>=[\%]?}
    rule color_rgb {:i'rgb('
                   <r=.color_arg> ','
                   <g=.color_arg> ','
                   <b=.color_arg>
                   [')' | <unclosed_paren>]
    }

    token prio {:i'!' [('important')|<skipped_term>]}

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

    # Error Recovery
    # --------------
    # term recovery - from within a declaration. skip to the next term,
    #                 or to the end of the block
    rule skipped_term  {<CSS::Grammar::Scan::value>+}

    # forward compatible scanning and recovery - from the stylesheet top level
    proto token unknown {*}
    # - try to skip whole statements or at-rules
    token unknown:sym<statement>   {<CSS::Grammar::Scan::statement>}
    # - if that failed, start skipping intermediate tokens
    token unknown:sym<value>       {<CSS::Grammar::Scan::value>}
    token unknown:sym<punct>       {<punct>}
    # - last resort skip a character; let parser try again
    token unknown:sym<char>        {<[.]>}
}


grammar CSS::Grammar::Scan is CSS::Grammar {

    # Fallback Grammar Only!!
    # This grammar is based on the syntax described in
    # http://www.w3.org/TR/2011/REC-CSS2-20110607/syndata.html#syntax
    # It is a scanning grammar that is only used to implement term flushing
    # for forward compatiblity and/or ignoring unknown constructs

    # It's been generalized to handle the rule dropping requirements outlined
    # in http://www.w3.org/TR/2003/WD-css3-syntax-20030813/#rule-sets
    # e.g this should be complety dropped: h3, h4 & h5 {color: red }
    # - there are a few more intermediate terms such as <declarations>
    #   and <declaration_list>
    # - added <op> for general purpose operator detection

    rule TOP          {^ <stylesheet> $}
    rule stylesheet   {<statement>*}
    rule statement    {<ruleset> | '@'<at_rule>}

    rule at_keyword   {\@<ident>}
    rule at_rule      {(<ident>) <any>* [<block> | ';']}
    rule block        {'{' [ <any> | <block> | <at_keyword> | ';' ]* '}'?}

    rule ruleset      {<selectors>? <declarations>}
    rule selectors    {<any>+}
    rule declarations {'{' <declaration_list> '}' ';'?}
    rule declaration_list {<declaration>? [';' <declaration>? ]* ';'?}
    rule declaration  {<property=.ident> ':' <value>}
    rule value        {[<any> | <block> | <at_keyword>]+}

    token delim       {<[\( \) \{ \} \; \" \' \\]>}
    token op          {[<punct><!after <delim>>]+}

    token dim         {<[a..zA..Z]>\w*}

    proto rule any { <...> }
    rule any:sym<string> { <string> }
    rule any:sym<num>    { <num>['%'|<dim>]? }
    rule any:sym<urange> { <unicode_range> }
    rule any:sym<ident>  { <ident> }
    rule any:sym<pseudo> { <pseudo> }
    rule any:sym<id>     { <id> }
    rule any:sym<class>  { <class> }
    rule any:sym<op>     { <op> }
    rule any:sym<attrib> { '[' [<any>|<unused>]* ']'? }
    rule any:sym<args>   { '(' [<any>|<unused>]* ')'? }

    rule unused {<block> | <at_keyword> | ';'}
}
