use v6;

grammar CSS::Grammar:ver<0.0.1> {

    # abstract base grammar for CSS instance grammars:
    #  CSS::Grammar::CSS1 - CSS level 1
    #  CSS::Grammar::CSS2 - CSS level 2.1
    #  CSS::Grammar::CSS3 - CSS level 3 (tba)

    # Comments and whitespace

    token nl {["\n"|"r\n"|"\r"|"\f"]+}

    token unclosed_comment {$}
    token comment {('<!--') [<nl>|.]*? ['-->' | <unclosed_comment>]
		  |('/*')  [<nl>|.]*?  ['*/'  | <unclosed_comment>]}

    token ws_char {"\n" | "\t" | "\f" | "\r" | " " | <comment> }

    token ws {<!ww><ws_char>*}

    # "lexer"

    rule unicode	{'\\'(<[0..9 a..f A..F]>**1..6)}
    rule nonascii	{<[\o241..\o377]>}
    rule escape		{<unicode>|'\\'<[\o40..~ ¡..ÿ]>}
    rule stringchar	{<escape>|<nonascii>|<[\o40 \! \# \$ \% \& \( .. \~]>}
    rule nmstrt		{<[a..z A..Z]>|<nonascii>|<escape>}
    rule nmchar		{<[\- a..z A..Z 0..9]>|<nonascii>|<escape>}
    rule ident		{<nmstrt><nmchar>*}
    rule name		{<nmchar>+}
    rule d		{<[0..9]>}
    rule notnm		{<-[\- a..z A..Z 0..9\\]>|<nonascii>}
    rule num		{[<d>*\.]?<d>+}
    rule string		{\"(<stringchar>|\')* $<closing_quote>=\"? | \'(<stringchar>|\")* $<closing_quote>=\'}

    rule id             {'#'<name>}
    rule class          {'.'<name>}

    rule percentage     {<num>'%'}
    rule length         {<num>(:i[pt|mm|cm|pc|in|px|em|ex])}
    rule angle          {<num>(:i[deg|rad|grad])}  # css2+
    rule time           {<num>(:i[m?s])}  # css2+
    rule freq           {<num>(:i[k?Hz])} # css2+
    # see discussion in http://www.w3.org/TR/CSS21/grammar.html G.3
    rule dimension      {<num>(<[a..zA..Z]>\w*)}

    token url_delim_char {\( | \) | "'"| '"' | <ws_char>}
    rule url_chars       {[<escape>|<- url_delim_char>]*}
    rule url_spec        {<string>|<url_chars>}

    # productions

    token url  {:i'url(' <ws_char>* <url_spec> <ws_char>* [')' | <unclosed_url>] }
    token unclosed_url {<!before ')'>}
    token rgb {:i'rgb('
		   <ws_char>* [<percentage>|<num>] <ws_char>* ','
		   <ws_char>* [<percentage>|<num>] <ws_char>* ','
		   <ws_char>* [<percentage>|<num>] <ws_char>* ')'}

    rule prio {:i'!important'}

    rule element_name {<ident>}

    # skip rules
    # - make sure they trigger <nl> - for accurate line counting
    rule skipped_term  {[<nl>|<string>|<-[;}]>]+}
}
