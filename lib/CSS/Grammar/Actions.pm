use v6;

# pushing this into the top level CSS namespace, a bit naughty, but...

enum CSS::Compat <css1 css2 css2_1 css3>;

# rules for constructing ASTs for CSS::Grammar

class CSS::Grammar::Actions {

    # variable encoding - not yet supported
    constant $encoding = 'ISO-8859-1';

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
	warn "calling a rule, wish me luck";
	my $ord =  _from_hex($0.Str);
	warn "encoding is: " ~ $.encoding;
	my $chr = Buf.new( $ord ).decode( $.encoding );
	make $chr;
    }

}

