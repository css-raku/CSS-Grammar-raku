use v6;

# rules for constructing ASTs for CSS::Grammar

class CSS::Grammar::Actions {

    use CSS::Grammar::AST::Info;

    has Int $.line_no is rw = 1;
    # variable encoding - not yet supported
    has $.encoding = 'ISO-8859-1';

    # accumulated warnings
    has @.warnings;

    method ast(Mu $ast, :$skip, :$type, ) {
        $ast
            does CSS::Grammar::AST::Info
            unless $ast.can('css_type');

        $ast.line_no = $.line_no;
        $ast.skip = $skip // False;
        $ast.css_type = $type if defined $type;

        return $ast;
    }

    method warning ($message, $str?) {
        my $warning = $message;
        $warning ~= ': ' ~ $str if $str;
        $warning does CSS::Grammar::AST::Info;
        $warning.line_no = $.line_no;
        push @.warnings, $warning;
    }

    method nl($/) {$.line_no++;}

    method skipped_term($/) {
        $.warning('skipping term', $/.Str);
    }

   method unicode($/) {
       my $ord =  _from_hex($0.Str);
       my $chr = Buf.new( $ord ).decode( $.encoding );
       make $chr;
    }
    method nonascii($/){make $/.Str}
    method escape($/){make $<unicode> ?? $<unicode>.ast !! $<char>.Str}
    method nmstrt($/){
        make $0 ?? $0.Str !! ($<nonascii> || $<escape>).ast;
    }
    method nmchar($/){
        make $0 ?? $0.Str !! ($<nonascii> || $<escape>).ast;
    }
    method ident($/) {
        make $<nmstrt>.ast ~ $<nmchar>.map({$_.ast}).join('');
    }
    method name($/) {
        make $<nmchar>.map({$_.ast}).join('');
    }
    method d($/) { make $/.Str }
    method notnum($/) { make $0.chars ?? $0.Str !! $<nonascii>.Str }
    method num($/) { make $/.Num }

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
        make $.ast($string, :type('string'), :skip($skip) );
    }

    method id($/) { make $<name>.ast }
    method class($/) { make $<name>.ast }

    role _Units_Stub {
        # interim units role; just until there's more appropriate modules
        # available. A role-based port of Math::Units or similar, might be in
        # order
        has Str $.units is rw;
    }

    method _qty($/) {
        my $qty = $<num>.ast
            does _Units_Stub;
        $qty.units = $0.Str;
        return $qty;
    }

    method percentage($/) { make $._qty($/); }
    method length($/) { make $._qty($/); }
    method angle($/) { make $._qty($/); }
    method time($/) { make $._qty($/); }
    method freq($/) { make $._qty($/); }
    method dimension($/) { make $._qty($/); }

    method url_char($/) {make $<escape> ?? $<escape>.ast !! $/.Str}
    method url_spec($/) {
        make $<string>
            ?? $<string>.ast
            !! $.ast( $<url_char>.map({$_.ast}).join('') );
    }
    method url($/) { make $<url_spec>.ast; }

    method rgb($/) {
        my %rgb;
        %rgb<r g b> = ($<r>, $<g>, $<b>);
        make %rgb;
    }

    method expr_missing($/) {
        $.warning("incomplete declaration");
    }

    method term:sym<dimension>($/) {
        $.warning('unknown dimensioned quantity', $/.Str);
        my $ast = $<dimension>.ast;
        make $.ast($ast, :skip(True));
    }

    method unclosed_comment($/) {
        $.warning('unclosed comment at end of input');
    }

    method unclosed_paren($/) {
        $.warning("missing closing ')'");
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
