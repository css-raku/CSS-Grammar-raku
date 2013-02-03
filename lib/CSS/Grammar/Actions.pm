use v6;

# rules for constructing ASTs for CSS::Grammar

class CSS::Grammar::Actions {

    use CSS::Grammar::AST;

    has Int $.line_no is rw = 1;
    method nl($/) {$.line_no++}

    method unclosed_comment($/) {
	make CSS::Grammar::AST.new(:line_no($.line_no),
				   :skip(False),
				   :warning("unclosed comment at end of input"));
    }
    method unclosed_declarations($/) {
	make CSS::Grammar::AST.new(:line_no($.line_no),
				   :skip(False),
				   :warning("missing '}' at end of input"));
    }
    method term:sym<dimension>($/) {
	make CSS::Grammar::AST.new(:line_no($.line_no),
				   :skip(True),
				   :warning('unknown dimensioned quantity'));
    }

    method unclosed_url($/) {
	make CSS::Grammar::AST.new(:line_no($.line_no),
				   :skip(False),
				   :warning("missing closing ')'"));
    }
    method skipped_term($/) {
	make CSS::Grammar::AST.new(:line_no($.line_no),
				   :skip(True),
				   :warning('unknown term'));
    }
    method late_at_rule($/) {
	# applicable to CSS1
	make CSS::Grammar::AST.new(:line_no($.line_no),
				   :skip(True),
				   :warning('out of sequence "@" rule'));
    }

    # variable encoding - not yet supported
    has $.encoding = 'ISO-8859-1';

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

}
