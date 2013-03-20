#!/usr/bin/env perl6

use Test;

use CSS::Grammar;
use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;
use CSS::Grammar::CSS3::Module::Fonts;

# prepare our own composite class with font extensions

grammar t::CSS3::FontGrammar
      is CSS::Grammar::CSS3::Module::Fonts
      is CSS::Grammar::CSS3
      {};

class t::CSS3::FontActions
    is CSS::Grammar::CSS3::Module::Fonts::Actions
    is CSS::Grammar::Actions
{};

use lib '.';
use t::AST;

my $css_actions = t::CSS3::FontActions.new;

for (
    at_rule   => {input => 'font-face {
                                font-family: Gentium;
                                src: url(http://example.com/fonts/Gentium.ttf);
                            };',
                  ast => {"declarations" => ["declaration" => {"property" => "font-family", "expr" => ["term" => "Gentium"]},
                                             "declaration" => {"property" => "src", "expr" => ["term" => "http://example.com/fonts/Gentium.ttf"]}], '@' => "font-face"}
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
