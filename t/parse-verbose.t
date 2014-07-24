#!/usr/bin/env perl6

use Test;

use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;
use CSS::Grammar::Test;

my $actions = CSS::Grammar::Actions.new( );

for (
    term => {input => '42%', ast => {"val" => 42, "units" => "\%"},
    },
    color-range => {input => '42%', ast => 107, # 42% of 255
    },
    term => {input => '#aa77Ff', ast => { "val" => { "r" => 170, "g" => 119, "b" => 255 }, "type" => "color", "units" => "rgb" },
    },
    term => {input => '#a7f', ast => { "val" => { "r" => 170, "g" => 119, "b" => 255 }, "type" => "color", "units" => "rgb" },
    },
    term => {input => '#a7g', ast => Mu,
             warnings => 'bad hex color: #a7g',
    },
    term => {input => '#a7fF', ast => Mu,
             warnings => 'bad hex color: #a7fF',
    },
    term => {input => 'rgb(17, 33, 70)', 
             ast => { "val" => { "r" => 17, "g" => 33, "b" => 70 }, "type" => "color", "units" => "rgb" },
    },
    term => {input => '1cm', ast => { "val" => 1, "type" => "length", "units" => "cm" }},
    term => {input => '-em', ast => { "val" => -1, type => 'length', units => 'em'}},
    term => {input => '-01.10', ast => { val => -1.1, type => 'num'}},
    term => {input => q{"Hello World"},
             ast => { val => q{Hello World}, type => 'string'},
    },
    term => {input => "'\\\nto \\\n\\\nbe \\\ncontinued\\\n'",
             ast => {val => 'to be continued', type => 'string'},
    },
    term => {input => q{url(http://example.com)},
             ast => {val => 'http://example.com',
                     type => 'url'},
    },
    expr => {input => 'foo(bar baz( 42 ) )',
             ast => [{"term" => [{"function" => "foo"},
                                 {"args" => [{"term" => {"type" => "ident", "val" => "bar"}},
                                             {"term" => [{"function" => "baz"},
                                                         {"args" => [{"term" => {"val" => 42, "type" => "num"}}]}]}]}]}
                 ],
    },
    # function without arguments, e.g. jquery-ui-themeroller.css
    expr => {input => 'mask()',
             ast => [{"term" => [{"function" => "mask"}]}],
    },
    unicode-range => {input => '416', ast => [ { "val" => 0x416, "type" => "code-point" }, { "val" => 0x416, "type" => "code-point" } ]},
    unicode-range => {input => '400-4FF', ast => [ { "val" => 0x400, "type" => "code-point" }, { "val" => 0x4FF, "type" => "code-point" } ]},
    unicode-range => {input => '4??', ast => [ { "val" => 0x400, "type" => "code-point" }, { "val" => 0x4FF, "type" => "code-point" } ]},
    ) {

    my $rule = .key;
    my $test = .value;
    my $input = $test<input>;

    CSS::Grammar::Test::parse-tests(CSS::Grammar::CSS3, $input,
				    :actions($actions),
				    :rule($rule),
				    :suite<css3>,
                                    :verbose,
				    :expected($test) );
}

done;
