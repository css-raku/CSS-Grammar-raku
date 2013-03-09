use v6;

grammar CSS::Grammar:ver<0.0.1> {

    # abstract base grammar for CSS instance grammars:
    #  CSS::Grammar::CSS1  - CSS level 1
    #  CSS::Grammar::CSS21 - CSS level 2.1
    #  CSS::Grammar::CSS3  - CSS level 3

    # Comments and whitespace

    token nl {"\n"|"\r\n"|"\r"|"\f"}

    token unclosed_comment {$}
    # comments: nb trigger <nl> for accurate line counting
    token comment {('<!--') [<nl>|.]*? ['-->' | <unclosed_comment>]
                  |('/*')  [<nl>|.]*?  ['*/'  | <unclosed_comment>]}

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
    token nmreg          {<[_ \- a..z A..Z 0..9]>+}
    token nmchar         {<nmreg>|<nonascii>|<escape>}
    token ident          {$<pfx>=['-']?<nmstrt><nmchar>*}
    token name           {<nmchar>+}
    token num            {[\d* \.]? \d+}

    proto token stringchar {<...>}
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

    proto token units {<...>}
    token units:sym<length>  {:i[pt|mm|cm|pc|in|px|em|ex]}
    token units:sym<percentage> {'%'}

    # see discussion in http://www.w3.org/TR/CSS21/grammar.html G.3
    token dimension      {<[a..zA..Z]>\w*}

    token url_delim_char {\( | \) | "'" | '"' | <wc>}
    token url_char       {<escape>|<nonascii>|<- url_delim_char>}
    token url_string     {<string>|<url_char>*}

    # productions

    rule url  {:i'url(' <url_string> [')' | <unclosed_paren>] }
    token unclosed_paren {''}

    rule emx {:i e[m|x]}

    rule color_arg{<num>$<percentage>=[\%]?}
    rule color_angle{<num>$<percentage>=[\%]?}
    rule color_alpha{<num>$<percentage>=[\%]?}

    rule color_rgb {:i'rgb('
                   <r=.color_arg> ','
                   <g=.color_arg> ','
                   <b=.color_arg>
                   [')' | <unclosed_paren>]
    }

    token prio {'!'[:i('important')|<skipped_term>]}

    # pseudos
    proto rule pseudo {<...>}
    rule pseudo:sym<element> {':' $<element>=[:i'first-'[line|letter]|before|after]}

    # Attribute selector - core set introduced with css2.1
    proto token attribute_selector {<...>}
    rule attribute_selector:sym<equals>    {'='}
    rule attribute_selector:sym<includes>  {'~='}
    rule attribute_selector:sym<dash>      {'|='}

    # Combinators - introduced with css2.1
    proto token combinator {<...>}
    token combinator:sym<adjacent> {'+'}
    token combinator:sym<child>   {'>'}

    # error recovery
    # - make sure they trigger <nl> - for accurate line counting
    token skipped_term  {[<wc>|<comment>|<string>|<-[;}]>]+}

    proto token unknown {<...>}
    token unknown:sym<string>      {<string>}
    token unknown:sym<name>        {<name>}
    token unknown:sym<nonascii>    {<nonascii>+}
    token unknown:sym<stringchars> {<stringchar>+}
}
