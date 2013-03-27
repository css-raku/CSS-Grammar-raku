#!/usr/bin/env perl6

use Test;

use CSS::Grammar::CSS21;
use CSS::Grammar::Actions;
use lib '.';
use t::AST;

my $css_actions = CSS::Grammar::Actions.new;

for (
    prop => {input => 'azimuth: 30deg',     ast => {angle => 30},
    },
    prop => {input => 'azimuth: far-right',  ast => {angle => 60},
    },
    prop => {input => 'azimuth: center-left behind',  ast => {angle => 200},
    },
    prop => {input => 'azimuth: Rightwards',  ast => {delta => 20},
    },
    prop => {input => 'azimuth: inherit',  ast => {inherit => True},
    },
    prop => {input => 'elevation: 65DEG',     ast => {angle => 65},
    },
    prop => {input => 'elevation: above',     ast => {angle => 90},
    },
    prop => {input => 'elevation: LOWER',     ast => {delta => -10},
    },
    prop => {input => 'background-attachment: Fixed',     ast => 'fixed',
    },
    prop => {input => 'background-attachment:inherit',     ast => 'inherit',
    },
    ) {

    my $rule = $_.key;
    my %test = $_.value;
    my $input = %test<input>;

    $css_actions.reset;
     my $p3 = CSS::Grammar::CSS21.parse( $input, :rule($rule), :actions($css_actions));
    t::AST::parse_tests($input, $p3, :rule($rule), :suite('css3'),
                         :warnings($css_actions.warnings),
                         :expected(%test) );
}

done;
