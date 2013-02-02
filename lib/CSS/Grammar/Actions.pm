use v6;

# rules for constructing ASTs for CSS::Grammar

class CSS::Grammar::Actions {

    has Int $line_counter is rw = 1;
    method nl($/) {$line_counter++}

    # warnings;
    has Bool $.warn is rw = True;
    method unclosed_comment($/) {
	warn "unclosed comment at end of input" if $.warn
    }
    method unclosed_rule($/) {
	warn "incomplete rule at end of input" if $.warn
    }
    method term:sym<dimension>($/) {
	warn 'unknown dimensioned quantity ' ~ $/.Str ~ " at line " ~ $line_counter
	    ~ '; skipping this declaration' ~ "\n"
	    if $.warn;
    }
    method at_rule:sym<skipped>($/) {
	warn 'unknown "@" rule ' ~ $/.Str ~ " at line " ~ $line_counter
	    ~ '; skipped' ~ "\n"
	    if $.warn;    }
    method unclosed_url($/) {
	warn "'url(' missing closing ')' at line " ~ $line_counter ~ "\n"
	    if $.warn;
    }
    method skipped_term($/) {
	warn 'unknown term ' ~ $/.Str ~ ' at line ' ~ $line_counter
	    ~ '; skipping this declaration' ~ "\n"
	    if $.warn;
    }
    method skipped_at_rule($/) {
	warn 'out of sequence "@" rule  ' ~ $/.Str ~ ' at line ' ~ $line_counter
	    ~ '; skipped' ~ "\n"
	    if $.warn;
    }

    # variable encoding - not yet supported
    has $.encoding = 'ISO-8859-1';

    # _lex method - just return token
    method _lex($/) {make $/.Str}

    sub _from_hex($hex) {

	my $result = 0;

	for $hex.split('') {

	    my $hex_digit;

	    if ($_ ge '0' && $_ le '9') {
		$hex_digit = $_;
	    }
	    elsif ($_ ge 'A' && $_ le 'F') {
		$hex_digit = ord($_) - ord('A') + 10;
	    }
	    elsif ($_ ge 'a' && $_ le 'f') {
		$hex_digit = ord($_) - ord('a') + 10;
	    }
	    else {
		# our grammar shouldn't allow this
		die "illegal hexidecimal digit: $_";
	    }

	    $result *= 16;
	    $result += $hex_digit;
	}
	return $result;
    }

    method unicode($/) {
	my $ord =  _from_hex($0.Str);
	my $chr = Buf.new( $ord ).decode( $.encoding );
	make $chr;
    }

}
