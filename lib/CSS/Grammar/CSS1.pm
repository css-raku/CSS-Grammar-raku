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

    rule unclosed_rule{$}

    rule ruleset {
	<selector> [',' <selector>]*
	    '{' <declaration> [';' <declaration> ]* ';'? ['}' | <unclosed_rule>]
    }

    rule property {<ident>}

    rule declaration {
	<property> ':' [<expr> <prio>?]?
    }

    rule expr { [<unary_operator>? <term> | <dropped_term>]
		    [  <operator>? <term> | <dropped_term>]* }


    proto rule term {<...>}

    rule term:sym<length>     {<length>}
    rule term:sym<percentage> {<percentage>}
    rule term:sym<dimension>  {<dimension>}
    rule term:sym<num>        {<num>}
    rule term:sym<ems>        {:i'em'}
    rule term:sym<exs>        {:i'ex'}
    rule term:sym<hexcolor>   {<id>}
    rule term:sym<rgb>        {<rgb>}
    rule term:sym<url>        {<url>}
    rule term:sym<ident>      {<ident>}

    rule dropped_term         {<-[;}]>+}

    token selector {<simple_selector>[<ws><simple_selector>]* <pseudo_element>?}

    token simple_selector { <element_name> <id>? <class>? <pseudo_class>?
	    | <id> <class>? <pseudo_class>?
	    | <class> <pseudo_class>?
	    | <pseudo_class> }

    rule pseudo {<pseudo_class>|<pseudo_element>}
    rule pseudo_class      {':'(:i link|visited|active)}
    rule pseudo_element    {':'(:i first\-[line|letter])}

    # 'lexer' css1 exceptions
    
    # -- css1 unicode escape sequences only extend to 4 chars
    rule unicode	{'\\'(<[0..9 a..f A..F]>**1..4)}
}
