use v6;

# rules for constructing ASTs for CSS::Grammar

class CSS::Grammar::Actions {

    use CSS::Grammar::AST::Info;

    has Int $.line_no is rw = 1;
    # variable encoding - not yet supported
    has $.encoding = 'ISO-8859-1';

    method ast($/, Mu $_ast?, :$warning, :$skip) {
        my $ast = '';
        $ast = $_ast if defined $_ast;

        $ast does CSS::Grammar::AST::Info;

        $ast.line_no = $.line_no;
        $ast.warning = $warning if defined $warning;
        $ast.skip = $skip if defined $skip;

        warn $warning ~ ': ' ~$/.Str ~ "\nat source line " ~ $.line_no
            if defined $warning;

        return $ast;
    }

    method end_block($/) {
        my $ast = $.ast($/);
        $ast.warning = 'assuming "}" at end of block'
            unless $<closing_paren>;

        make $ast;
    }

    method late_at_rule($/) {
        # applicable to CSS1
        make $.ast($/, :warning('out of sequence "@" rule') );
    }

    method nl($/) {$.line_no++; make $.ast($/)}

    method skipped_term($/) {
        make $.ast($/, :warning('unknown term') );
    }

    method string($/) {
        my $ast = $.ast($/);

        unless $<closing_quote>.Str {
            $ast.skip = True;
            $ast.warning = 'unclosed string';
        }

        make $ast;
    }

    method term:sym<dimension>($/) {
        make $.ast($/, :skip(True),
                   :warning('unknown dimensioned quantity') );
    }

    method unclosed_url($/) {
        make $.ast($/, :skip(False),
                    :warning("missing closing ')'") );
    }

    method unclosed_comment($/) {
        make $.ast($/, :skip(False),
                    :warning("unclosed comment at end of input"));
    }

   method unicode($/) {
       my $ord =  _from_hex($0.Str);
       my $chr = Buf.new( $ord ).decode( $.encoding );
       make $.ast($/, $chr );
    }

    # utiltity methods / subs

    sub _from_hex($hex) is pure {

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
