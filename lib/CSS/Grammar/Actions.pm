use v6;

# rules for constructing ASTs for CSS::Grammar

class CSS::Grammar::Actions {

    use CSS::Grammar::AST::Info;

    has Int $.line_no is rw = 1;
    # variable encoding - not yet supported
    has $.encoding = 'ISO-8859-1';

    # accumulated warnings
    has @.warnings;

    method ast($/, Mu $_ast?, :$skip) {
        my $ast = $_ast || $/.Str;

        $ast does CSS::Grammar::AST::Info;

        $ast.line_no = $.line_no;
        $ast.skip = $skip if defined $skip;

        return $ast;
    }

    method warning ($message, $str?) {
        my $warning = $message;
        $warning ~= ': ' ~ $str if $str;
        $warning does CSS::Grammar::AST::Info;
        $warning.line_no = $.line_no;
        push @.warnings, $warning;
    }

    method nl($/) {$.line_no++; make $.ast($/)}

    method skipped_term($/) {
        $.warning('skipping term', $/.Str);
    }

    method escape($/){make $<unicode> ?? $<unicode>.ast !! $<char>.Str}
    method nonascii($/){make $/.Str}

    method stringchar:sym<escape>($/)   { make $<escape>.ast }
    method stringchar:sym<nonascii>($/) { make $<nonascii>.ast }
    method stringchar:sym<ascii>($/)    { make $/.Str }

    method string($/) {
        my Bool $skip = False;
        unless ($<closing_quote>.Str) {
            $.warning('unterminated string');
            $skip = True;
        }
        my $string = $<stringchar>.map({ $_.ast }).join('');
        make $.ast($/, $string, :skip($skip) );
    }

    method expr_missing($/) {
        $.warning("incomplete declaration");
    }

    method term:sym<dimension>($/) {
        $.warning('unknown dimensioned quantity', $/.Str);
        make $.ast($/, :skip(True));
    }

    method unclosed_comment($/) {
        $.warning('unclosed comment at end of input');
    }

    method unclosed_paren($/) {
        $.warning("missing closing ')'");
    }

   method unicode($/) {
       my $ord =  _from_hex($0.Str);
       my $chr = Buf.new( $ord ).decode( $.encoding );
       make $.ast($/, $chr );
    }

    method end_block($/) {
        $.warning("no closing '}'")
            unless $<closing_paren>;
    }

    # this can get a bit too verbose
    method unknown:sym<string>($/) {$.warning('skipping', $/)}
    method unknown:sym<name>($/) {$.warning('skipping', $/)}
    method unknown:sym<nonascii>($/) {$.warning('skipping', $/)}
    method unknown:sym<stringchars>($/) {$.warning('skipping', $/)}
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
