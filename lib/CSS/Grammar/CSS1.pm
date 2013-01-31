use v6;

use CSS::Grammar;

grammar CSS::Grammar::CSS1 is CSS::Grammar {

# as defined in w3c Appendix B: CSS1 Grammar
# http://www.w3.org/TR/REC-CSS1/#appendix-b

    rule TOP {^ <stylesheet> $}

    # comb; rule to reduce a css3, css2 or generally noisy stylesheet,
    # to a cleaner, parseable, css1 subset:
    # my $css1 = $css_input.comb(/<CSS::Grammar::CSS1::comb>/)

    rule comb { <at_rule> | <!after \@><ruleset> }

    # productions

    rule stylesheet { <at_rule>* <ruleset>* }

    proto rule at_rule { <...> }
    rule at_rule:sym<import> { \@[:i import] [<string>|<url>] ';' }
    rule at_rule:sym<dropped> { \@(\w+) [<string>|<url>] ';'| <ruleset> }

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

    rule term:sym<length>   {<sym>}
    rule term:sym<dropped>  {<dimension>}
    rule term:sym<ems>      {:i em}
    rule term:sym<exs>      {:i ex}
    rule term:sym<ident>    {<sym>}
    rule term:sym<hexcolor> {<id>}
    rule term:sym<url>      {<sym>}
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
    
    # -- css1 unicode escape sequences only extend to 4 chars
    rule unicode	{'\\'(<[0..9 a..f A..F]>**1..4)}

    # unquoted strings - as permitted in urls
    rule url_delimiter   {<ws_char> | <[\, \' \" \( \) \\ ]>}
    rule url_escape_seq  {'\\'<url_delimiter>?}

    rule url_char        {[<- url_delimiter>|<url_escape_seq>]}
    rule url_spec        {<string>|<url_char>+} 
}
