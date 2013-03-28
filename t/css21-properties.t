#!/usr/bin/env perl6

use Test;

use CSS::Grammar::CSS21;
use CSS::Grammar::Actions;
use lib '.';
use t::AST;

my $css_actions = CSS::Grammar::Actions.new;

for (
    prop => {input => 'azimuth: 30deg',       ast => (azimuth => [angle => 30]),
    },
    prop => {input => 'Azimuth : far-right',  ast => (azimuth => [angle => 60]),
    },
    prop => {input => 'azimuth: center-left behind',  ast => (azimuth => [angle => 200]),
    },
    prop => {input => 'AZIMUTH : Rightwards',  ast => (azimuth => [delta => 20]),
    },
    prop => {input => 'azimuth: inherit',     ast => (azimuth => [inherit => True]),
    },
    prop => {input => 'elevation: 65DEG',     ast => (elevation => [angle => 65]),
    },
    prop => {input => 'elevation:above',      ast => (elevation => [angle => 90]),
    },
    prop => {input => 'elevation : LOWER',    ast => (elevation => [delta => -10]),
    },
    prop => {input => 'background-attachment: FiXed',   ast => ('background-attachment' => [ident => 'fixed']),
    },
    prop => {input => 'Background-Attachment :inherit', ast => ('background-attachment' => [inherit => True]),
    },
    prop => {input => 'background-color : #37a', ast => ('background-color' => [color => { rgb => {r => 0x33, g => 0x77, b => 0xAA}}]),
    },
    prop => {input => 'background-image : url(images/ok.png)', ast => ('background-image' => [uri => 'images/ok.png']),
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
