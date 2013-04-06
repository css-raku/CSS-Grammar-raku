#!/usr/bin/env perl6

use Test;

use CSS::Grammar;
use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;
use CSS::Grammar::CSS3x::Fonts;

# prepare our own composite class with font extensions

grammar t::CSS3::FontGrammar
      is CSS::Grammar::CSS3x::Fonts
      is CSS::Grammar::CSS3
      {};

class t::CSS3::FontActions
    is CSS::Grammar::CSS3x::Fonts::Actions
    is CSS::Grammar::Actions
{};

use lib '.';
use t::AST;

my $css_actions = t::CSS3::FontActions.new;

for (
    at_rule   => {input => q:to 'END_INPUT',
                           font-face {
                                  font-family: MainText;
                                  src: url(gentium.eot); /* for use with older non-conformant user agents */
                                  src: local("Gentium"), url(gentium.ttf) format("truetype");  /* Overrides src definition */
                                }
                           END_INPUT
                  ast => {"declarations" => {"font-family" => {"expr" => ["term" => "maintext"]},
                                             "src" => {"expr" => ["term" => {"ident" => "local", "args" => ["string" => "Gentium"]},
                                                                  "operator" => ",",
                                                                  "term" => "gentium.ttf",
                                                                  "term" => {"ident" => "format", "args" => ["string" => "truetype"]}]}},
                          '@' => "font-face"},
    },
    ) {
    my $rule = $_.key;
    my %test = $_.value;
    my $input = %test<input>;

    $css_actions.reset;
    my $p3 = t::CSS3::FontGrammar.parse( $input, :rule($rule), :actions($css_actions));
    t::AST::parse_tests($input, $p3, :rule($rule), :suite('css3-font-composite'),
                         :warnings($css_actions.warnings),
                         :expected(%test) );
}

done;
