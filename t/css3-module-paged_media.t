#!/usr/bin/env perl6

use Test;

use CSS::Grammar;
use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;
use CSS::Grammar::CSS3::Module::PagedMedia;

# prepare our own composite class with paged media extensions

grammar t::CSS3::PagedMediaGrammar
      is CSS::Grammar::CSS3
      is CSS::Grammar::CSS3::Module::PagedMedia {};

class t::CSS3::PagedMediaActions
    is CSS::Grammar::Actions
    is CSS::Grammar::CSS3::Module::PagedMedia::Actions {};


use lib '.';
use t::CSS;

my $css_actions = t::CSS3::PagedMediaActions.new;

# to do: nested rule-sets. grammars?

my $top_center = '
@page { color: red;
        @top-center {
           content: "Page " counter(page);
       }
}';

my $top_center_ast = {
    "page_declarations" => ["declaration" => {"property" => {"ident" => "color"},
                                              "expr" => ["term" => {"ident" => "red"}]},
                            "page_box" => {"page_pos" => {"hpos" => "center", "vpos" => "top"},
                                           "declarations" => ["declaration" => {"property" => {"ident" => "content"}, "expr" => ["term" => {"string" => "Page "},
                                                                                                                                 "term" => {"function" => {"ident" => "counter", "expr" => ["term" => {"ident" => "page"}]}}]}]
                            }
        ]
};

for (
    at_rule   => {input => '@page :left { margin-left: 4cm; }',
                  ast => {"page_pseudo" => "left", "page_declarations" => ["declaration" => {"property" => {"ident" => "margin-left"}, "expr" => ["term" => {length => 4}]}]},
    },
    at_rule   => {input => '@page :junk { margin-right: 2cm }',
                  ast => {"page_declarations" => ["declaration" => {"property" => {"ident" => "margin-right"}, "expr" => ["term" => {length => 2}]}]},
                  warnings => 'ignoring page pseudo: junk',
    },
    at_rule   => {input => '@page : { margin-right: 2cm }',
                  ast => Mu,
                  warnings => "':' should be followed by one of: left right first",
    },
    page_pos => {input => 'top-left', ast => {hpos => 'left', vpos => 'top'}},
    page_pos => {input => 'top-center', ast => {hpos => 'center', vpos => 'top'}},
    page_pos => {input => 'RIGHT-TOP', ast => {hpos => 'right', vpos => 'top'}},
    page_pos => {input => 'bottom-left-corner', ast => {hpos => 'left', vpos => 'bottom'}},
    page_pos => {input => 'bottom-right', ast => {hpos => 'right', vpos => 'bottom'}},
    page_box => {input => '@bottom-right {color:blue}',
                 ast => {"page_pos" => {"hpos" => "right", "vpos" => "bottom"},
                         "declarations" => ["declaration" => {"property" => {"ident" => "color"}, "expr" => ["term" => {"ident" => "blue"}]}]},
    },
    page_box => {input => '@top-center {content: "Page " counter(page);}',
                 ast => {"page_pos" => {"hpos" => "center", "vpos" => "top"},
                         "declarations" => ["declaration" => {"property" => {"ident" => "content"}, "expr" => ["term" => {"string" => "Page "}, "term" => {"function" => {"ident" => "counter", "expr" => ["term" => {"ident" => "page"}]}}]}]},
    },
    at_rule => {input => $top_center, ast => $top_center_ast},
    ) {
    my $rule = $_.key;
    my %test = $_.value;
    my $input = %test<input>;

    $css_actions.warnings = ();
    my $p3 = t::CSS3::PagedMediaGrammar.parse( $input, :rule($rule), :actions($css_actions));
    t::CSS::parse_tests($input, $p3, :rule($rule), :compat('css3 at-rule'),
                         :warnings($css_actions.warnings),
                         :expected(%test) );
}

done;
