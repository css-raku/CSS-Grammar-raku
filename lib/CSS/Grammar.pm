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

    token unicode	{'\\'(<[0..9 a..f A..F]>**1..6)}
    token nonascii	{<[\o241..\o377]>}
    token escape		{<unicode>|'\\'$<char>=<[\o40..~ ¡..ÿ]>}
    token stringchar	{<escape>|<nonascii>|$<char>=<[\o40 \! \# \$ \% \& \( .. \~]>}
    token nmstrt		{<[a..z A..Z]>|<nonascii>|<escape>}
    token nmchar		{<[\- a..z A..Z 0..9]>|<nonascii>|<escape>}
    token ident		{<nmstrt><nmchar>*}
    token name		{<nmchar>+}
    token d		{<[0..9]>}
    token notnm		{<-[\- a..z A..Z 0..9\\]>|<nonascii>}
    token num		{[<d>*\.]?<d>+}
    token string		{\"(<stringchar>|\')* $<closing_quote>=\"? | \'(<stringchar>|\")* $<closing_quote>=\'}

    token id             {'#'<name>}
    token class          {'.'<name>}

    token percentage     {<num>'%'}
    token length         {<num>(:i[pt|mm|cm|pc|in|px|em|ex])}
    token angle          {<num>(:i[deg|rad|grad])}  # css2+
    token time           {<num>(:i[m?s])}  # css2+
    token freq           {<num>(:i[k?Hz])} # css2+
    # see discussion in http://www.w3.org/TR/CSS21/grammar.html G.3
    token dimension      {<num>(<[a..zA..Z]>\w*)}

    token url_delim_char {\( | \) | "'"| '"' | <ws_char>}
    token url_chars       {[<escape>|<- url_delim_char>]*}
    token url_spec        {<string>|<url_chars>}

    # productions

    token url  {:i'url(' <ws_char>* <url_spec> <ws_char>* [')' | <unclosed_url>] }
    token unclosed_url {<!before ')'>}
    token rgb {:i'rgb('
		   <ws_char>* [<percentage>|<num>] <ws_char>* ','
		   <ws_char>* [<percentage>|<num>] <ws_char>* ','
		   <ws_char>* [<percentage>|<num>] <ws_char>* ')'}

    token prio {:i'!important'}

    token element_name {<ident>}

    # skip rules
    # - make sure they trigger <nl> - for accurate line counting
    token skipped_term  {[<nl>|<string>|<-[;}]>]+}
}
