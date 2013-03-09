#!/usr/bin/env perl6

use Test;

use CSS::Grammar;
use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;
use CSS::Grammar::CSS3::Module::Colors;

# prepare our own composite class with color extensions

grammar t::CSS3::ColorGrammar
      is CSS::Grammar::CSS3
      is CSS::Grammar::CSS3::Module::Colors {};

class t::CSS3::ColorActions
    is CSS::Grammar::Actions
    is CSS::Grammar::CSS3::Module::Colors::Actions {};

use lib '.';
use t::CSS;

my $css_actions = t::CSS3::ColorActions.new;

for (
    term   => {input => 'rgb(70%, 50%, 10%)',
               ast => {r => 179, g => 127, b => 26},
               token => {type => 'color', units => 'rgb'},
    },
    term   => {input => 'rgba(100%, 50%, 0%, 0.1)',
               ast => {r => 255, g => 127, b => 0, a=> .1},
               token => {type => 'color', units => 'rgba'},
    },
    term   => {input => 'hsl(120, 100%, 50%)',
               ast => {h => 120, 's' => 1, 'l' => .5},
               token => {type => 'color', units => 'hsl'},
    },
    term   => {input => 'hsla(50%, 100%, .5, 75%)',
               ast => {h => 180, 's' => 1, 'l' => .5, 'a' => .75},
               token => {type => 'color', units => 'hsla'},
    },
    at_rule => {input => '@color-profile { name: acme_cmyk; src: url(http://printers.example.com/acmecorp/model1234); }',
                ast => {"declarations" => ["declaration" => {"property" => "name",
                                                             "expr" => ["term" => "acme_cmyk"]},
                                           "declaration" => {"property" => "src",
                                                             "expr" => ["term" => "http://printers.example.com/acmecorp/model1234"]}],
                        '@' => "color-profile"},
    },
    ) {
    my $rule = $_.key;
    my %test = $_.value;
    my $input = %test<input>;

    $css_actions.warnings = ();
    my $p3 = t::CSS3::ColorGrammar.parse( $input, :rule($rule), :actions($css_actions));
    t::CSS::parse_tests($input, $p3, :rule($rule), :compat('css3-color-composite'),
                         :warnings($css_actions.warnings),
                         :expected(%test) );
}

done;
