use v6;

use CSS::Grammar::Actions;

class CSS::Grammar::Scan::Actions
    is  CSS::Grammar::Actions {

    method nmstart($/) {
	my $ch = $0 ?? $0.Str !! ($<nonascii> || $<escape>).ast;
	make $ch.match(/<[_ a..z A..Z]>/) ?? $ch !! '\\' ~ :16( ord($ch) );
    }

    method nmchar($/) {
        my $ch = $<nmreg> ?? $<nmreg>.Str !! ($<nonascii> || $<escape>).ast;
	make $ch.match(/\w|\-/) ?? $ch !! '\\' ~ :16( ord($ch) );
    }

    method ident-cleanup($/) {
	make [~] $/.caps.map({
           .key eq 'ident' ?? .value.ast !! .value.Str
	});
    }

}
