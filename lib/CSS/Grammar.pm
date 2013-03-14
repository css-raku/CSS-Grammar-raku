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
    token ww {<?after \w><?before \w>}
    token ws {<!ww>[<wc>|<comment>]*}

    # "lexer"com
    # taken from http://www.w3.org/TR/css3-syntax/ 11.2 Lexical Scanner

    token unicode        {'\\'(<[0..9 a..f A..F]>**1..6)}
    # w3c nonascii :== #x80-#xD7FF #xE000-#xFFFD #x10000-#x10FFFF
    token regascii       {<[\x20..\x7F]>}
    token nonascii       {<- [\x0..\x7F]>}
    token escape         {<unicode>|'\\'$<char>=[<regascii>|<nonascii>]}
    token nmstrt         {(<[_ a..z A..Z]>)|<nonascii>|<escape>}
    token nmreg          {<[_ \- a..z A..Z 0..9]>+}
    token nmchar         {<nmreg>|<nonascii>|<escape>}
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

    # see discussion in http://www.w3.org/TR/CSS21/grammar.html G.3
    token dimension      {<[a..zA..Z]>\w*}

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

    # Attribute selector - core set introduced with css2.1
    proto token attribute_selector {*}
    token attribute_selector:sym<equals>    {'='}
    token attribute_selector:sym<includes>  {'~='}
    token attribute_selector:sym<dash>      {'|='}

    # Combinators - introduced with css2.1
    proto token combinator {*}
    token combinator:sym<adjacent> {'+'}
    token combinator:sym<child>    {'>'}

    # Uncode ranges - used by selector modules + any rules
    proto rule unicode_range {*}
    rule unicode_range:sym<from_to> {$<from>=[<xdigit> ** 1..6] '-' $<to>=[<xdigit> ** 1..6]}
    rule unicode_range:sym<masked>  {[<xdigit>|'?'] ** 1..6}

    # Error Recovery
    # --------------
    # - make sure they trigger <nl> - for accurate line counting
    token skipped_term  {[<wc>|<comment>|<CSS::Grammar::Scan::value>|<-[;}]>]+}

    # - forward compatible scanning and recovery
    proto token unknown {*}

    # try to skip complete statments
    token unknown:sym<statement>   {<CSS::Grammar::Scan::statement>}

    # if that failed, start skipping intermediate tokens
    token unknown:sym<any>         {<CSS::Grammar::Scan::any>}
    token unknown:sym<unused>      {<CSS::Grammar::Scan::unused>}

    # nah? skip punctuaton and low level chars
    token unknown:sym<nonascii>    {<nonascii>+}
    token unknown:sym<stringchars> {<stringchar>+}
    token unknown:sym<punct>       {<punct>}

    # last resort - just throw out a character and try again
    token unknown:sym<char>        {<[.]>}
}


grammar CSS::Grammar::Scan is CSS::Grammar {

    # Fallback Grammar Only!!
    # This grammar is based on the syntax described in
    # http://www.w3.org/TR/2011/REC-CSS2-20110607/syndata.html#syntax
    # It is a scanning grammar that is only used to implement term flushing
    # for forward compatiblity and/or unknown constructs

    # It's needed a little more structure to ensure parsing of valid stylesheets
    # - added <prio> to declarations
    # - added <combinator> plus level 3 attrbute selectors
    # - added <selectors> rule. handle ',' + combinators
    # - added <punctation> for various operators and extensions

    rule TOP         {^ <stylesheet> $}
    rule stylesheet  {<statement>*}
    rule statement   {<ruleset> | '@'<at_rule>}

    token at_keyword {\@<ident>}
    rule at_rule     {(<ident>) <any>* [<block> | ';']}
    rule block       {'{' [<any> | <block> | <at_keyword> | ';']* <end_block>}
    rule end_block   {[$<closing_paren>='}' ';'?]?}

    rule ruleset     { <selectors>  '{' <declaration>? [';' <declaration>? ]* ';'? <end_block> }
    rule selectors   { <selector> [',' <selector>]* }
    rule selector    {<any>[[<.ws>?<combinator><.ws>?]? <any>]*}
    rule declaration {<property> ':' <value> <prio>?}
    rule property    {<ident>}
    rule value       {[<any> | <block> | <at_keyword>]+}

    # inherit some level 2 & level 3 extensions
    token attribute_selector:sym<ext> {'^='|'$='|'*='}
    token combinator:sym<ext> {'-'|'~'}

    proto token any {<...>}
    token any:sym<string> { <string> }
    token any:sym<num>    { <num>[<units>|<dimension>]? }
    token any:sym<urange> { <unicode_range> }
    token any:sym<ident>  { <ident> }
    token any:sym<id>     { <id> }
    token any:sym<class>  { <class> }
    token any:sym<attsel> { <attribute_selector> }
    token any:sym<punc>   { ':' | '+' | '-' | '/' | ','}
    token any:sym<attrib> { '[' [<any>|<unused>] ']' }
    token any:sym<args>   { '(' [<any>|<unused>] ')' }

    rule unused {<block> | <at_keyword> | ';'}
}
