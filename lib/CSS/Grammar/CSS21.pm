use v6;

use CSS::Grammar;

grammar CSS::Grammar::CSS21 is CSS::Grammar {

# as defined in w3c Appendix G: Grammar of CSS 2.1
# http://www.w3.org/TR/CSS21/grammar.html

    rule TOP {^ <stylesheet> $}

    # comb; rule to reduce a css3+ or hand-coded stylesheet, to a  cleaner,
    # css2 parsable subset:
    # my $css2 = $css_input.comb(/<CSS::Grammar::CSS2::comb>/)

    rule comb { <charset> | <import> | <at_rule> | <ruleset> }

    # productions

    rule stylesheet { <charset>? <import>* <decl>* }
    rule decl { $<ignored>=[<charset>|<import>] | <at_rule> | <ruleset> }

    rule charset { \@(:i'charset') $<charset>=<string> ';' }
    rule import  { \@(:i'import')  $<import>=[<string>|<url>] ';' }

    proto rule at_rule { <...> }
    rule at_rule:sym<media>   { \@(:i'media') <media_list> <rulesets> }
    rule at_rule:sym<page>    { \@(:i'page')  $<page>=<pseudo>? <declarations> }

    rule media_list {<medium> [',' <medium>]*}
    rule medium {<ident>}
    rule media_props {'{' <ruleset>* $<closing_paren>='}'? }

    rule unary_operator {'-'}

    rule operator {'/'|','}

    rule combinator {'-'|'+'}

    rule ruleset {
	<!after \@> # not an "@" rule
	<selector> [',' <selector>]* <declarations>
    }

    rule property {<ident>}

    rule declarations {
	'{' <declaration> [';' <declaration> ]* ';'? <end_block>
    }

    rule rulesets {
	'{' <ruleset>* <end_block>
    }

    rule end_block {[$<closing_paren>='}' ';'?]?}

    rule declaration {
	 <property> ':' [<expr> <prio>?]?
    }

    rule expr { <unary_operator>? <term_etc>
		    [  <operator>? <term_etc>]* }

    rule term_etc {<term>|<skipped_term>}

    proto rule term {<...>}
    rule term:sym<length>     {<length>}
    rule term:sym<angle>      {<angle>}
    rule term:sym<freq>       {<freq>}
    rule term:sym<percentage> {<percentage>}
    rule term:sym<dimension>  {<dimension>}
    rule term:sym<num>        {<num>}
    rule term:sym<ems>        {:i'em'}
    rule term:sym<exs>        {:i'ex'}
    rule term:sym<hexcolor>   {<id>}
    rule term:sym<url>        {<url>}
    rule term:sym<rgb>        {<rgb>}
    rule term:sym<ident>      {<ident>}
    rule term:sym<function>   {<function>}

    token selector {<simple_selector>[<combinator> <selector>|<ws>[<combinator>? <selector>]?]?}

    token simple_selector { <element_name> [<id> | <class> | <pseudo>]*
				| [<id> | <class> | <pseudo>]+ }

    rule pseudo       {':' [<function>|<ident>] }
    rule function     { <ident>'(' <expr> ')' }

    # 'lexer' css2 exceptions
}
