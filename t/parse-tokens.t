#!/usr/bin/env perl6

use Test;

use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;
use lib '.';
use t::CSS;

my $css_actions = CSS::Grammar::Actions.new;

for (
    term => {input => '#eeeeee', ast => 'eeeeee',
             token => {type => 'color', units => 'hex'},
    },
    term => {input => 'rgb(17%, 33%, 70%)',
             token => {type => 'color', units => 'rgb'},
             ast => {r => 17, g => 33, b => 70},
    },
    term => {input => 'rgb(17%, 33%, 70%',
             warnings => ["missing closing ')'"],
             ast => {r => 17, g => 33, b => 70},
    },
    term => {input => '1cm', ast => 1,
             token => {type => 'length', units => 'cm'}},
    term => {input => '-em', ast => -1, token => {type => 'length', units => 'em'}},
    term => {input => '-01.10', ast => -1.1,
             token => {type => 'num'}},
    term => {input => q{"Hello World"},
             ast => q{Hello World},
             token => {type => 'string', skip => False},
    },
    term => {input => q{"Hello 'Black H},
             ast => q{Hello 'Black H},
             token => {type => 'string', skip => True},
             warnings => ['unterminated string'],
    },
    term => {input => q{url(http://example.com)},
             ast => 'http://example.com',
             token => {type => 'url'},
    },
    term => {input => q{url("http://example.com/2/"},
             ast => 'http://example.com/2/',
             token => {type => 'url'},
             skip=> False,
             warnings => "missing closing ')'",
    },
    # function without arguments, e.g. jquery-ui-themeroller.css
    term => {input => 'mask()',
             ast => {"ident" => "mask"},
             token => {type => 'function'},
             css1 => {
                 parse => 'mask',
                 ast => {ident => 'mask'},
             },
    },
    ) {

    my $rule = $_.key;
    my %test = $_.value;
    my $input = %test<input>;

    $css_actions.warnings = ();
     my $p3 = CSS::Grammar::CSS3.parse( $input, :rule($rule), :actions($css_actions));
    t::CSS::parse_tests($input, $p3, :rule($rule), :compat('css3'),
                         :warnings($css_actions.warnings),
                         :expected(%test) );
}

done;
