use v6;

use CSS::Grammar;

grammar CSS::Grammar::CSS1 is CSS::Grammar {

# as defined in w3c Appendix B: CSS1 Grammar
# http://www.w3.org/TR/REC-CSS1/#appendix-b

    rule TOP {^ <stylesheet> $}

    # combing rule; to reduce a css3 or css1 ruleset to a css1 subset, use
    # my $css1 = $css3.comb(/<CSS::Grammar::CSS1::strands>/)
    rule strands {<import>|<!after \@><ruleset>}

    # productions

    rule stylesheet {<import>* <ruleset>*}

    rule import { \@[:i import] [<string>|<url>] ';' }

    rule unary_operator {'-'|'+'}

    rule operator {'/'|','}

    rule ruleset {
	<selector> [',' <selector>]*
	    '{' <declaration> [';' <declaration> ]* ';'? '}'
    }

    rule property {<ident>}

    rule declaration {
	 <property> ':' <expr> <prio>?
    }

    rule expr { <term> [ <operator>? <term> ]* }

    rule term { <unary_operator>?
		    [ <length> | $<misc>=<dimension> | <string> | <percentage>
		      | <num> | <ems> | <exs> | <ident> | <hexcolor> | <url> | <rgb> ]}

    rule ems {:i em}
    rule exs {:i ex}
    rule hexcolor {<id>}

    rule rgb{:i 'rgb' '(' <num>('%'?) ','  <num>('%'?) ','  <num>('%'?) ')' }

    rule prio {:i \!important}

    regex selector {<simple_selector>[<ws><simple_selector>]* <pseudo_element>?}

    regex simple_selector { <element_name> <id>? <class>? <pseudo_class>?
	    | <id> <class>? <pseudo_class>?
	    | <class> <pseudo_class>?
	    | <pseudo_class> }

    rule element_name {<ident>}

    rule  pseudo_class      {':'(:i link|visited|active)}
    rule  pseudo_element    {':'(:i first\-[line|letter])}

    rule url  {:i 'url(' <text> ')' }

    # 'lexer' css1 exceptions
    
    # -- unicode escape sequences only extend to 4 chars
    rule unicode	{'\\'(<[0..9 a..f A..F]>**1..4)}

}
