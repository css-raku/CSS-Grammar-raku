use v6;

use CSS::Grammar;

grammar CSS::Grammar::CSS2 is CSS::Grammar {

# as defined in w3c Appendix G: Grammar of CSS 2.1
# http://www.w3.org/TR/CSS21/grammar.html

    rule TOP {^ <stylesheet> $}

    # comb; rule to reduce a css3, or generally noisy stylesheet, to a
    # cleaner, parsable css2 subset:
    # my $css2 = $css_input.comb(/<CSS::Grammar::CSS2::comb>/)

    rule comb { <at_rule> | <!after \@><ruleset> }

    # productions

    rule stylesheet { [ <at_rule> | <ruleset> ]* }

    proto rule at_rule { <...> }
    rule at_rule:sym<charset> { \@[:i charset] <string> ';' }
    rule at_rule:sym<import>  { \@[:i import] [<string>|<url>] ';' }
    rule at_rule:sym<media>   { \@[:i media] <media_list> '{' <ruleset> '}' ';'? }
    rule at_rule:sym<page>    { \@[:i page] $<puesdo_page>=<ident>?
		                '{' <declaration> [';' <declaration> ]* ';'? '}'
    }
    rule at_rule:sym<dropped> { \@(\w+) [<string>|<url>] ';'| <ruleset> }

    rule media_list {<medium> [',' $<medium>=<ident>]*}

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

    rule term:sym<length angle freq percentage>
                              {<sym>}
    rule term:sym<dropped>    {<dimension>}
    rule term:sym<num>        {<sym>}
    rule term:sym<ems>        {:i em}
    rule term:sym<exs>        {:i ex}
    rule term:sym<ident>      {<sym>}
    rule term:sym<hexcolor>   {<id>}
    rule term:sym<url>        {<sym>}
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
