use v6;

grammar CSS::Grammar:ver<0.0.1> {

    # abstract base grammar for CSS instance grammars:
    #  CSS::Grammar::CSS1  - CSS level 1
    #  CSS::Grammar::CSS21 - CSS level 2.1
    #  CSS::Grammar::CSS3  - CSS level 3 (tba)

    # Comments and whitespace

    token nl {"\n"|"r\n"|"\r"|"\f"}

    token unclosed_comment {$}
    # comments: nb trigger <nl> for accurate line counting
    token comment {('<!--') [<nl>|.]*? ['-->' | <unclosed_comment>]
                  |('/*')  [<nl>|.]*?  ['*/'  | <unclosed_comment>]}

    token ws_char {<nl> | "\t"  | " " | <comment>}

    token ws {<!ww><ws_char>*}

    # "lexer"

    token unicode        {'\\'(<[0..9 a..f A..F]>**1..6)}
    token nonascii       {<[\o200..\o377]>}
    token escape         {<unicode>|'\\'$<char>=<[\o40..~ \o200..\o377]>}
    token nmstrt         {(<[_ a..z A..Z]>)|<nonascii>|<escape>}
    token nmchar         {(<[_ \- a..z A..Z 0..9]>)|<nonascii>|<escape>}
    token ident          {('-')?<nmstrt><nmchar>*}
    token name           {<nmchar>+}
    token d              {<[0..9]>}
    token notnm          {(<-[\- a..z A..Z 0..9\\]>)|<nonascii>}
    token num            {[<d>*\.]?<d>+}

    proto token stringchar {<...>}
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

    token url_delim_char {\( | \) | "'" | '"' | <ws_char>}
    token url_char       {<escape>|<- url_delim_char>}
    token url_string     {<string>|<url_char>*}

    # productions

    rule url  {:i'url(' <url_string> [')' | <unclosed_paren>] }
    token unclosed_paren {''}

    rule rgb {:i'rgb('
                   [<r=.percentage>|<r=.num>] ','
                   [<g=.percentage>|<g=.num>] ','
                   [<b=.percentage>|<b=.num>]
                   [')' | <unclosed_paren>]
    }

    token prio {'!'[:i('important')|<skipped_term>]}

    token element_name {<ident>}

    # error recovery
    # - make sure they trigger <nl> - for accurate line counting
    token skipped_term  {[<ws_char>|<string>|<-[;}]>]+}

    proto token unknown {<...>}
    token unknown:sym<string>      {<string>}
    token unknown:sym<name>        {<name>}
    token unknown:sym<nonascii>    {<nonascii>+}
    token unknown:sym<stringchars> {<stringchar>+}
}
