use v6;

use CSS::Grammar;

grammar CSS::Grammar::CSS1 is CSS::Grammar {

# as defined in w3c Appendix B: CSS1 Grammar
# http://www.w3.org/TR/REC-CSS1/#appendix-b

    rule TOP {^ <stylesheet> $}

    # rinse; to reduce a css3 or css2 ruleset to a css1 subset, or
    # for general cleaning of real-world input use
    # my $css1 = $css3.comb(/<CSS::Grammar::CSS1::rinse>/)

    rule rinse { <import> | <!after \@><ruleset> }

    # productions

    rule stylesheet { <import>* <ruleset>* }

    rule import { \@[:i import] [<string>|<url>] ';' }

    rule unary_operator {'-'|'+'}

    rule operator {'/'|','}

    rule ruleset {
	<selector> [',' <selector>]*
	    '{' <declaration> [';' <declaration> ]* ';'? ('}' | $)
    }

    rule property {<ident>}

    rule declaration {
	<property> ':' [<expr> <prio>?]?
    }

    rule expr {  <unary_operator>? <term> [ <operator>? <term> ]* }

    proto rule term { <...> }

    rule term:sym<length>   {<length>}
    rule term:sym<dropped>  {<dimension>}
    rule term:sym<ems>      {:i em}
    rule term:sym<exs>      {:i ex}
    rule term:sym<ident>    {<ident>}
    rule term:sym<hexcolor> {<id>}
    rule term:sym<url>      {<url>}
    rule term:sym<rgb>      {:i 'rgb' '(' <num>('%'?)
                                      ',' <num>('%'?)
                                      ',' <num>('%'?)
                                      ')' }
    token term:sym<guff> {<- [;}]>+}

    rule prio {:i \!important}

    regex selector {<simple_selector>[<ws><simple_selector>]* <pseudo_element>?}

    regex simple_selector { <element_name> <id>? <class>? <pseudo_class>?
	    | <id> <class>? <pseudo_class>?
	    | <class> <pseudo_class>?
	    | <pseudo_class> }

    rule element_name {<ident>}

    rule  pseudo {<pseudo_class>|<pseudo_element>}
    rule  pseudo_class      {':'(:i link|visited|active)}
    rule  pseudo_element    {':'(:i first\-[line|letter])}

    rule url  {:i 'url(' <url_spec> ')' }

    # 'lexer' css1 exceptions
    
    # -- unicode escape sequences only extend to 4 chars
    rule unicode	{'\\'(<[0..9 a..f A..F]>**1..4)}

    # unquoted strings - as permitted in urls
    rule url_quotable    {<ws_char> | <[\, \' \" \( \) \\ ]>}
    rule url_escape_seq  {'\\'<url_quotable>?}

    rule url_char        {[<- url_quotable>|<url_escape_seq>]}
    rule url_spec        {<string>|<url_char>+} 
}
