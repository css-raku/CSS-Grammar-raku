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

    rule expr { <unary_operator>? <term> [ <operator>? <term> ]* }

    proto rule term { <...> }

    rule term:sym<length>     {<length>}
    rule term:sym<angle>      {<angle>}
    rule term:sym<time>       {<time>}
    rule term:sym<freq>       {<freq>}
    rule term:sym<string>     {<string>}
    rule term:sym<percentage> {<percentage>}
    rule term:sym<dropped>    {<dimension>}
    rule term:sym<num>        {<num>}
    rule term:sym<ems>        {:i em}
    rule term:sym<exs>        {:i ex}
    rule term:sym<ident>      {<ident>}
    rule term:sym<hexcolor>   {<id>}
    rule term:sym<url>        {<url>}
    rule term:sym<rgb>        {:i 'rgb' '(' <num>('%'?)
                                        ',' <num>('%'?)
                                        ',' <num>('%'?)
                                        ')' }

    rule term:sym<function> {<function>}
    token term:sym<guff> {<- [;}]>+}

    rule prio {:i \!important}

    regex selector {<simple_selector>[<combinator> <selector>|<ws>[<combinator>? <selector>]?]?}

    regex simple_selector { <element_name> [<id> | <class> | <pseudo>]*
				| [<id> | <class> | <pseudo>]+ }

    rule element_name {<ident>}
    rule pseudo       {':' <ident> | <function> <ident>? }
    rule url          {:i 'url(' <url_spec> ')' }
    rule function     { '(' <expr> ')' }

    # 'lexer' css2 exceptions
}
