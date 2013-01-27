use v6;

grammar CSS::Grammar {

    # Comments and whitespace

    token eol {"\r\n"  # ms/dos
               | "\n"  #'nix
               | "\r"} # mac-osx

    token ws_char {'<!--' .*? '-->'
                   |'/*' .*? '*/'
		   | "\n" | "\t" | "\o12" | "\f" | "\r" | " "}

    token ws {
	<!ww>
	<ws_char>*}

    # "lexer"

    rule unicode	{'\\'(<[0..9 a..f A..F]>**1..6)}
    rule latin1		{<[\o241..\o377]>}
    rule escape		{<unicode>|'\\'<[' '..~¡..ÿ]>}
    rule stringchar	{<escape>|<latin1>|<[\o40 \! \# \$ \% \& \( .. \~]>}
    rule nmstrt		{<[a..z A..Z]>|<latin1>|<escape>}
    rule nmchar		{<[\- a..z A..Z 0..9]>|<latin1>|<escape>}
    rule ident		{<nmstrt><nmchar>*}
    rule name		{<nmchar>+}
    rule d		{<[0..9]>}
    rule notnm		{<-[\- a..z A..Z 0..9\\]>|<latin1>}
    rule num		{[<d>*\.]?<d>+}
    rule string		{\"(<stringchar>|\')*\" | \'(<stringchar>|\")*\'}

    rule id             {'#'<name>}
    rule class          {'.'<name>}

    rule percentage     {<num>'%'}
    rule length         {<num>(:i pt|mm|cm|pc|in|px|em|ex)}
    rule time           {<num>(:i m?s)}  # css2
    rule freq           {<num>(:i k?Hz)} # css2
    # see discussion in http://www.w3.org/TR/CSS21/grammar.html G.3
    rule dimension {<num><[\w]>+}

    # unquoted strings - as permitted in urls
    rule quotable_char         {<ws_char> | <[\, \' \" \( \) \\ ]>}
    rule unquoted_escape_seq   {'\\'<quotable_char>?}
    rule unquoted_string       {[<-quotable_char>|<unquoted_escape_seq>]+}
    rule text {<string>|<unquoted_string>}

}
