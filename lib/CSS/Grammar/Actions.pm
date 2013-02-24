use v6;

use CSS::Grammar::CSS3::Module::Selectors;

# rules for constructing ASTs for CSS::Grammar

class CSS::Grammar::Actions
    is CSS::Grammar::CSS3::Module::Selectors::Actions {

    use CSS::Grammar::AST::Info;

    has Int $.line_no is rw = 1;
    # variable encoding - not yet supported
    has $.encoding = 'UTF-8';

    # accumulated warnings
    has @.warnings;

    method leaf(Mu $ast, :$skip, :$type, ) {
        # make a leaf element (token)
        $ast
            does CSS::Grammar::AST::Info
            unless $ast.can('css_type');

        $ast.line_no = $.line_no;
        $ast.skip = $skip // False;
        $ast.css_type = $type if defined $type;

        return $ast;
    }

    method node($/) {
        # make an intermediate node
        my %terms;

        for $/.caps -> $cap {
            my ($key, $value) = $cap.kv;
            $value = $value.ast;
            next unless defined $value;
            die "repeated term: " ~ $key ~ " (use .list, implement custom method, or refactor grammar)"
                if %terms.exists($key);

            %terms{$key} = $value;
        }

        return %terms;
    }

    method list($/) {
        # make a node that contains repeatable elements
        my @terms;

        for $/.caps -> $cap {
            my ($key, $value) = $cap.kv;
            $value = $value.ast;
            next unless defined $value;
            push @terms, ($key => $value);
        }

        return @terms;
    }

    sub _display_string($str) {

        my %unesc = (
            "\n" => '\n',
            "\r" => '\t',
            "\f" => '\f',
            "\\"  => '\\',
            );

        $str.split('').map({
            my $c = %unesc{$_} // (
               $_ ~~ /<[\t\o40 \!..\~]>/ ?? $_ !! sprintf "\\x[%x]", $_.ord
            )
       }).join('');
    }

    method warning ($message, $str?) {
        my $warning = $message;
        $warning ~= ': ' ~ _display_string( $str.chomp )
            if defined $str;
        $warning does CSS::Grammar::AST::Info;
        $warning.line_no = $.line_no;
        push @.warnings, $warning;
    }

    method nl($/) {$.line_no++;}

    method element_name($/) {make $<ident>.ast}

    method skipped_term($/) {
        $.warning('skipping term', $/.Str);
    }

    method _to_unicode($str) {
        my $ord = _from_hex($str);
        return Buf.new( $ord ).decode( $.encoding );
    }

    method unicode($/) {
       make $._to_unicode( $0.Str );
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
        my $dash = $0 ?? $0.Str !! '';
        make $dash ~ $<nmstrt>.ast ~ $<nmchar>.map({$_.ast}).join('');
    }
    method name($/) {
        make $<nmchar>.map({$_.ast}).join('');
    }
    method notnum($/) { make $0.chars ?? $0.Str !! $<nonascii>.Str }
    method num($/) { make $/.Num }

    method stringchar:sym<cont>($/)     { make '' }
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
        make $.leaf($string, :type('string'), :skip($skip) );
    }

    method id($/) { make $<name>.ast }
    method class($/) { make $<name>.ast }

    role _Units_Stub {
        # interim units role; just until there's more appropriate modules
        # available. A role-based port of Math::Units or similar, might be
        # in order
        has Str $.units is rw;
    }

    method _qty($/) {
        my $qty = $<num>.ast
            does _Units_Stub;
        $qty.units = $0.Str;
        return $qty;
    }

    method percentage($/) { make $._qty($/); }
    method length($/)     { make $._qty($/); }
    method angle($/)      { make $._qty($/); }
    method time($/)       { make $._qty($/); }
    method freq($/)       { make $._qty($/); }
    method dimension($/)  { make $._qty($/); }

    method url_char($/) {
        my $cap = $<escape> || $<nonascii>;
        make $cap ?? $cap.ast !! $/.Str
    }
    method url_string($/) {
        make $<string>
            ?? $<string>.ast
            !! $.leaf( $<url_char>.map({$_.ast}).join('') );
    }
    method url($/)  { make $<url_string>.ast }
    method color_rgb($/)  { make $.node($/) }
    method prio($/) { make $0.Str.lc if $0}

    # from the TOP (CSS1 + CSS21)
    method TOP($/) { make $<stylesheet>.ast }
    method stylesheet($/) { make $.list($/) }

    method charset($/)   { make $<string>.ast }
    method import($/)    { make $.node($/) }
    method namespace($/) { make $.node($/) }

    method unexpected($/) {
        $.warning('ignoring out of sequence directive', $/.Str)
    }
    method unexpected2($/) {
        $.warning('ignoring out of sequence directive', $/.Str)
    }
    method at_rule:sym<media>($/) { make $.node($/) }
    method at_rule:sym<page>($/) { make $.node($/) }

    method media_list($/) { make $.node($/) }
    method medium($/) { make $.node($/) }

    method operator($/) { make $.leaf($/.Str) }
    method combinator($/) { make $.leaf($/.Str) }

    # css2
    method ruleset($/)      { make $.node($/) }
    method property($/)     { make $.node($/) }
    method declarations($/) { make $.list($/) }
    method rulesets($/)     { make $.list($/) }
    method declaration($/)  { make $.node($/) }

    method expr($/) { make $.list($/) }

    method expr_missing($/) {
        $.warning("incomplete declaration");
    }

    method pterm:sym<length>($/)        { make $<length>.ast }
    method pterm:sym<angle>($/)         { make $<angle>.ast }
    method pterm:sym<time>($/)          { make $<time>.ast }
    method pterm:sym<freq>($/)          { make $<freq>.ast }
    method pterm:sym<percentage>($/)    { make $<percentage>.ast }
    method pterm:sym<dimension>($/)     {
        $.warning('unknown dimensioned quantity', $/.Str);
        my $ast = $<dimension>.ast;
        make $.leaf($ast, :skip(True));
    }
    method pterm:sym<num>($/)           { make $<num>.ast }
    method pterm:sym<ems>($/)           { make $.leaf($/.Str.lc) }
    method pterm:sym<exs>($/)           { make $.leaf($/.Str.lc) }

    method aterm:sym<string>($/)        { make $<string>.ast }
    method aterm:sym<url>($/)           { make $<url>.ast }
    method aterm:sym<color_hex>($/)     { make $<id>.ast }
    method aterm:sym<color_rgb>($/)     { make $<color_rgb>.ast }
    method aterm:sym<function>($/)      { make $<function>.ast }
    method aterm:sym<unicode_range>($/) { make $<unicode_range>.ast }
    method aterm:sym<ident>($/)         { make $<ident>.ast }

    method term($/) {
        if $<term> && defined (my $term_ast = $<term>.ast) {
            $term_ast does CSS::Grammar::AST::Info
                unless $term_ast.can('unary_operator');
            $term_ast.unary_operator = $<unary_operator>.Str
                if $<unary_operator>;
            make $term_ast;
        }
        else {
            ##make (skipped => $<skipped_term>.ast);
        }
    }

    method unicode_range($/) { make $<range>.ast }
    method range:sym<from_to>($/) {
        # don't produce actual hex chars; could be out of range
        make [ _from_hex($<from>.Str), _from_hex($<to>.Str) ];
    }

    method range:sym<masked>($/) {
        my $mask = $/.Str;
        my $lo = $mask.subst('?', '0'):g;
        my $hi = $mask.subst('?', 'F'):g;

        # don't produce actual hex chars; could be out of range
        make [ _from_hex($lo), _from_hex($hi) ];
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

    # todo: warnings can get a bit too verbose here
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
