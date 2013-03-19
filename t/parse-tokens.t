#!/usr/bin/env perl6

use Test;

use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;
use lib '.';
use t::AST;

my $css_actions = CSS::Grammar::Actions.new;

for (
    term => {input => '42%', ast => 42,
             token => {type => 'percentage'},
    },
    color_arg => {input => '42%', ast => 107, # 42% of 255
             token => {type => 'num'},
    },
    term => {input => '#aa77Ff', ast => {r => 0xAA, g => 0x77, b => 0xFF},
             token => {type => 'color', units => 'rgb'},
    },
    term => {input => '#a7f', ast => {r => 0xAA, g => 0x77, b => 0xFF},
             token => {type => 'color', units => 'rgb'},
    },
    term => {input => '#a7g', ast => Mu,
             warnings => 'bad hex color: #a7g',
    },
    term => {input => '#a7fF', ast => Mu,
             warnings => 'bad hex color: #a7fF',
    },
    term => {input => 'rgb(17, 33, 70)',
             token => {type => 'color', units => 'rgb'},
             ast => {r => 17, g => 33, b => 70},
    },
    term => {input => 'rgb(17%, 33%, 70%',
             warnings => ["missing closing ')'"],
             ast => {r => 43, g => 84, b => 179},
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
    term => {input => "'\\\nto \\\n\\\nbe \\\ncontinued\\\n'",
             ast => 'to be continued',
             token => {type => 'string'},
    },
    term => {input => q{url(http://example.com)},
             ast => 'http://example.com',
             token => {type => 'url'},
    },
    term => {input => q{url("http://example.com/2/"},
             ast => 'http://example.com/2/',
             token => {type => 'url', skip => False},
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
    t::AST::parse_tests($input, $p3, :rule($rule), :suite('css3'),
                         :warnings($css_actions.warnings),
                         :expected(%test) );
}

done;
