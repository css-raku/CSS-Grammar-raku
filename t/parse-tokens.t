#!/usr/bin/env perl6

use Test;

use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;
use CSS::Grammar::Test;

my $actions = CSS::Grammar::Actions.new;

for (
    term => {input => '42%', ast => 42,
             token => {type => 'percentage'},
    },
    color-range => {input => '42%', ast => 107, # 42% of 255
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
    term => {input => '1cm', ast => 1,
             token => {type => 'length', units => 'cm'}},
    term => {input => '-em', ast => -1, token => {type => 'length', units => 'em'}},
    term => {input => '-01.10', ast => -1.1,
             token => {type => 'num'}},
    term => {input => q{"Hello World"},
             ast => q{Hello World},
             token => {type => 'string'},
    },
    term => {input => "'\\\nto \\\n\\\nbe \\\ncontinued\\\n'",
             ast => 'to be continued',
             token => {type => 'string'},
    },
    term => {input => q{url(http://example.com)},
             ast => 'http://example.com',
             token => {type => 'url'},
    },
    expr => {input => 'foo(bar baz( 42 ) )',
             ast => Mu,
    },
    # function without arguments, e.g. jquery-ui-themeroller.css
    expr => {input => 'mask()',
             ast => Mu,
    },
    unicode-range => {input => '416', ast => [0x416, 0x416]},
    unicode-range => {input => '400-4FF', ast => [0x400, 0x4FF]},
    unicode-range => {input => '4??', ast => [0x400, 0x4FF]},
    ) {

    my $rule = .key;
    my $test = .value;
    my $input = $test<input>;

    CSS::Grammar::Test::parse-tests(CSS::Grammar::CSS3, $input,
				    :actions($actions),
				    :rule($rule),
				    :suite<css3>,
				    :expected($test) );
}

done;
