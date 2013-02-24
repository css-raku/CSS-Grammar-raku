use v6;

grammar CSS::Grammar:ver<0.0.1> {

    # abstract base grammar for CSS instance grammars:
    #  CSS::Grammar::CSS1  - CSS level 1
    #  CSS::Grammar::CSS21 - CSS level 2.1
    #  CSS::Grammar::CSS3  - CSS level 3

    # Comments and whitespace

    token nl {"\n"|"r\n"|"\r"|"\f"}

    token unclosed_comment {$}
    # comments: nb trigger <nl> for accurate line counting
    token comment {('<!--') [<nl>|.]*? ['-->' | <unclosed_comment>]
                  |('/*')  [<nl>|.]*?  ['*/'  | <unclosed_comment>]}

    token wc {<nl> | "\t"  | " "}

    token ws {<!ww>[<wc>|<comment>]*}

    # "lexer"
    # Taken from http://www.w3.org/TR/css3-syntax/ 11.2 Lexical Scanner
    # todo: \o377 should be \o4177777. Rakudo (and flex) can't handle this yet

    token unicode        {'\\'(<[0..9 a..f A..F]>**1..6)}
    # w3c nonascii :== #x80-#xD7FF #xE000-#xFFFD #x10000-#x10FFFF
    token nonascii       {<- [\x0..\x7F]>}
    token regascii       {<[\x20..\x7E]>}
    token escape         {<unicode>|'\\'$<char>=[<regascii>|<nonascii>]}
    token nmstrt         {(<[_ a..z A..Z]>)|<nonascii>|<escape>}
    token nmchar         {(<[_ \- a..z A..Z 0..9]>)|<nonascii>|<escape>}
    token ident          {('-')?<nmstrt><nmchar>*}
    token name           {<nmchar>+}
    token notnm          {(<-[\- a..z A..Z 0..9\\]>)|<nonascii>}
    token num            {[\d* \.]? \d+}

    proto token stringchar {<...>}
    token stringchar:sym<cont>      {\\<nl>}
    token stringchar:sym<escape>    {<escape>}
    token stringchar:sym<nonascii>  {<nonascii>}
    token stringchar:sym<ascii>     {<[\o40 \! \# \$ \% \& \( .. \~ \' \"]>}

    token single_quote   {\'}
    token double_quote   {\"}
    token string         {\"[<!before \"><stringchar>]*$<closing_quote>=\"?
                         |\'[<!before \'><stringchar>]*$<closing_quote>=\'?}

    token id             {'#'<name>}
    token class          {'.'<name>}

    token percentage     {<num>('%')}
    token length         {<num>(:i[pt|mm|cm|pc|in|px|em|ex])}
    token angle          {<num>(:i[deg|rad|grad])}  # css2+
    token time           {<num>(:i[m?s])}  # css2+
    token freq           {<num>(:i[k?Hz])} # css2+
    # see discussion in http://www.w3.org/TR/CSS21/grammar.html G.3
    token dimension      {<num>(<[a..zA..Z]>\w*)}

    token url_delim_char {\( | \) | "'" | '"' | <wc>}
    token url_char       {<escape>|<nonascii>|<- url_delim_char>}
    token url_string     {<string>|<url_char>*}

    # productions

    rule url  {:i'url(' <url_string> [')' | <unclosed_paren>] }
    token unclosed_paren {''}

    rule color_rgb {:i'rgb('
                   [<r=.percentage>|<r=.num>] ','
                   [<g=.percentage>|<g=.num>] ','
                   [<b=.percentage>|<b=.num>]
                   [')' | <unclosed_paren>]
    }

    token prio {'!'[:i('important')|<skipped_term>]}

    token element_name {<ident>}

    rule pseudo_ident     {<pseudo_keyw>|<pseudo_foreign>}

    proto token pseudo_keyw {<...>}
    token pseudo_keyw:sym<pclass> {:i(link|visited|active)}
    token pseudo_keyw:sym<element> {:i(first\-[line|letter])}

    token pseudo_foreign {<ident>}

    # Attribute selector - core set introduced with css2.1
    proto token attribute_selector {<...>}
    rule attribute_selector:sym<equals>    {'='}
    rule attribute_selector:sym<includes>  {'~='}
    rule attribute_selector:sym<dash>      {'|='}

    # error recovery
    # - make sure they trigger <nl> - for accurate line counting
    token skipped_term  {[<wc>|<comment>|<string>|<-[;}]>]+}

    proto token unknown {<...>}
    token unknown:sym<string>      {<string>}
    token unknown:sym<name>        {<name>}
    token unknown:sym<nonascii>    {<nonascii>+}
    token unknown:sym<stringchars> {<stringchar>+}
}
