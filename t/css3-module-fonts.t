#!/usr/bin/env perl6

use Test;

use CSS::Grammar;
use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;
use CSS::Grammar::CSS3::Module::Fonts;

# prepare our own composite class with font extensions

grammar t::CSS3::FontGrammar
      is CSS::Grammar::CSS3
      is CSS::Grammar::CSS3::Module::Fonts {};

class t::CSS3::FontActions
    is CSS::Grammar::Actions
    is  CSS::Grammar::CSS3::Module::Fonts::Actions {};

use lib '.';
use t::CSS;

my $css_actions = t::CSS3::FontActions.new;

for (
    at_rule   => {input => '@font-face {
                                font-family: Gentium;
                                src: url(http://example.com/fonts/Gentium.ttf);
                            };',
                  ast => {"declarations" => ["declaration" => {"property" => {"ident" => "font-family"}, "expr" => ["term" => {ident => "Gentium"}]},
                                             "declaration" => {"property" => {"ident" => "src"}, "expr" => ["term" => {url => "http://example.com/fonts/Gentium.ttf"}]}]}
    },
    ) {
    my $rule = $_.key;
    my %test = $_.value;
    my $input = %test<input>;

    $css_actions.warnings = ();
    my $p3 = t::CSS3::FontGrammar.parse( $input, :rule($rule), :actions($css_actions));
    t::CSS::compat_tests($input, $p3, :rule($rule), :compat('css3-font-composite'),
                         :warnings($css_actions.warnings),
                         :expected(%test) );
}

done;
