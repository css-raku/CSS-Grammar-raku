use v6;

use CSS::Grammar;

grammar CSS::Grammar::CSS2 is CSS::Grammar {

# as defined in w3c Appendix B: CSS1 Grammar
# http://www.w3.org/TR/REC-CSS1/#appendix-b

    rule TOP {^ <stylesheet> $}

    # rinse; to reduce a css3 ruleset to a css2 subset, or
    # for general cleaning of real-world input use
    # my $css2 = $css3.comb(/<CSS::Grammar::CSS2::rinse>/)

    rule rinse { <charset> | <import> | <!after \@><ruleset> | <media> | <page> }

    # productions

    rule stylesheet { [ <charset>* <import>* <ruleset> | <media> | <page> ]* }

    rule charset { \@[:i charset] <string> ';' }

    rule import { \@[:i import] [<string>|<url>] ';' }

    rule media { \@[:i media] <media_list> '{' <ruleset> '}' ';' }
    rule media_list {<medium> [',' <medium>]*}
    rule medium {<ident>}

    rule page { \@[:i page] <page> <puesdo_page>?
		    '{' <declaration> [';' <declaration> ]* ';'? '}'
    }

    rule unary_operator {'-'}

    rule operator {'/'|','}

    rule combinator {'-'|'+'}

    rule ruleset {
	<selector> [',' <selector>]*
	    '{' <declaration> [';' <declaration> ]* ';'? ('}' | $)
    }

    rule property {<ident>}

    rule declaration {
	 <property> ':' [<expr> <prio>?]?
    }

    rule expr { <term> [ <operator>? <term> ]* }

    rule term { <unary_operator>?
		    [ <length> | <angle> | <time> | <freq> | <string> | <percentage> | <dimension>
		      | <num> | <ems> | <exs> | <ident> | <hexcolor> | <url> | <rgb> | <function> | <guff> ]}

    token guff {<- [;}]>+}
    rule ems {:i em}
    rule exs {:i ex}
    rule hexcolor {<id>}

    rule rgb{:i 'rgb' '(' <num>('%'?) ','  <num>('%'?) ','  <num>('%'?) ')' }

    rule prio {:i \!important}

    regex selector {<simple_selector>[<combinator> <selector>|<ws>[<combinator>? <selector>]?]?}

    regex simple_selector { <element_name> [<id> | <class> | <pseudo>]*
				| [<id> | <class> | <pseudo>]+ }

    rule element_name {<ident>}

    rule  pseudo      {':' <ident> | <function> <ident>? }

    rule url  {:i 'url(' <text> ')' }

    rule function { '(' <expr> ')' }

    # 'lexer' css2 exceptions
}
