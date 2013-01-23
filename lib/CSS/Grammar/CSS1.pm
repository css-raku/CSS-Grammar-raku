use v6;

use CSS::Grammar;

grammar CSS::Grammar::CSS1 is CSS::Grammar {

# as defined in w3c Appendix B: CSS1 Grammar
# http://www.w3.org/TR/REC-CSS1/#appendix-b

rule TOP {^ <stylesheet> $}

# productions

rule stylesheet {<import>* <ruleset>*}

rule import { \@import [<string>|<url>] ';' }

rule unary_operator {'-'|'+'}

rule operator {'/'|','}

rule property {<ident>}

rule ruleset {
    <selector> [',' <selector>]*
	'{' <declaration> [';' <declaration> ]* '}'
}

rule declaration {
     <property> ':' <expr> <prio>?
}

rule prio {\! important}

regex selector {<simple_selector>+ <pseudo_element>?}

regex simple_selector {[<element_name> <id>? <class>? <pseudo_class>?]
	| [ <id> <class>? <pseudo_class>?]
	| [ <class> <pseudo_class>?]
	| <pseudo_class>}

rule element_name {<ident>}

rule  pseudo_class      {':'(link|visited|active)}
rule  pseudo_element    {<ident>?':'(first\-[line|letter])}

rule url { 'url(' [<string>|<unquoted_string>] ')' }

# "lexer"

rule unicode		{'\\'<[0..9 a..f A..F]>**1..4}
rule latin1		{<[\o241..\o377]>}
rule  escape		{<unicode>|'\\'<[' '..~¡..ÿ]>}
rule  stringchar	{<escape>|<latin1>|<[\o40 \! \# \$ \% \& \( .. \~]>}
rule  nmstrt		{<[a..z A..Z]>|<latin1>|<escape>}
rule  nmchar		{<[\- a..z A..Z 0..9]>|<latin1>|<escape>}
rule  ident		{<nmstrt><nmchar>*}
rule  name		{<nmchar>+}
rule d			{<[0..9]>}
rule  notnm		{<-[\- a..z A..Z 0..9\\]>|<latin1>}
rule num		{<d>+|[<d>*\.<d>+]}
rule  string		{\"(<stringchar>|\')*\" | \'(<stringchar>|\")*\'}

rule  quotable_char  {<ws_char> | <[\, \' \" \( \) \\ ]>}
rule  unquoted_escape_seq   {'\\'<quotable_char>?}
rule  unquoted_string       {[<-quotable_char>|<unquoted_escape_seq>]+}

rule  percentage        {<num>'%'}
rule  length            {<num>(pt|mm|cm|pc|in|px|em|ex)}

rule id                 {'#'<name>}
rule class              {'.'<name>}

}
