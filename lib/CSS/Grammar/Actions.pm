use v6;

# rules for constructing ASTs for CSS::Grammar

class CSS::Grammar::Actions {

    use CSS::Grammar::AST::Info;

    has Int $.line_no is rw = 1;
    # variable encoding - not yet supported
    has $.encoding = 'ISO-8859-1';

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
            next unless defined $value.ast;
            $key = $key.subst(/_etc$/, '');
            die "repeated term: " ~ $key ~ " (use .list, implement custom method, or refactor grammar)"
                if %terms.exists($key);

            %terms{$key} = $value.ast;
        }

        return %terms;
    }

    method list($/) {
        # make a node that contains repeatable elements
        my @terms;

        for $/.caps -> $cap {
            my ($key, $value) = $cap.kv;
            next unless defined $value.ast;
            $key = $key.subst(/_etc$/, '');
            push @terms, ($key => $value.ast);
        }

        return @terms;
    }

    method etc($/) {
        # grouping node that contains one matched child
        my ($cap) = $/.caps;
        return $cap.value.ast;
    }

    method warning ($message, $str?) {
        my $warning = $message;
        $warning ~= ': ' ~ $str if $str;
        $warning does CSS::Grammar::AST::Info;
        $warning.line_no = $.line_no;
        push @.warnings, $warning;
    }

    method nl($/) {$.line_no++;}

    method element_name($/) {make $<ident>.ast}

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
        my $dash = $0 ?? $0.Str !! '';
        make $dash ~ $<nmstrt>.ast ~ $<nmchar>.map({$_.ast}).join('');
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

    method url_char($/) {make $<escape> ?? $<escape>.ast !! $/.Str}
    method url_string($/) {
        make $<string>
            ?? $<string>.ast
            !! $.leaf( $<url_char>.map({$_.ast}).join('') );
    }
    method url($/)  { make $<url_string>.ast }
    method rgb($/)  { make $.node($/) }

    # from the TOP (CSS1 + CSS21)
    method TOP($/) { make $<stylesheet>.ast }
    method stylesheet($/) { make $.list($/) }
    method import_etc($/) { make $.etc($/) }
    method rule_etc($/)   { make $.etc($/) }

    method charset($/) { make $.leaf( $<charset>.ast ) }
    method import($/)  { make $.node($/) }

    method  at_rule:sym<media>($/) { make $.node($/) }
    method  at_rule:sym<page>($/) { make $.node($/) }

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

    method uterm:sym<length>($/)     { make $<length>.ast }
    method uterm:sym<angle>($/)      { make $<angle>.ast }
    method uterm:sym<freq>($/)       { make $<freq>.ast }
    method uterm:sym<percentage>($/) { make $<percentage>.ast }
    method uterm:sym<dimension>($/)  {
        $.warning('unknown dimensioned quantity', $/.Str);
        my $ast = $<dimension>.ast;
        make $.leaf($ast, :skip(True));
    }
    method uterm:sym<num>($/)        { make $<num>.ast }
    method uterm:sym<ems>($/)        { make $.leaf($/.Str.lc) }
    method uterm:sym<exs>($/)        { make $.leaf($/.Str.lc) }

    method term:sym<string>($/)     { make $<string>.ast }
    method term:sym<hexcolor>($/)   { make $<id>.ast }
    method term:sym<url>($/)        { make $<url>.ast }
    method term:sym<rgb>($/)        { make $<rgb>.ast }
    method term:sym<function>($/)   { make $<function>.ast }
    method term:sym<ident>($/)      { make $<ident>.ast }

    method term_etc($/) {
        if $<term> && defined (my $term_ast = $<term>.ast) {
            $term_ast does CSS::Grammar::AST::Info
                unless $term_ast.can('unary_operator');
            $term_ast.unary_operator = $<unary_operator>.Str
                if $<unary_operator>;
            make $term_ast;
        }
        else {
            make $.etc($/);
        }
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

    method selector($/) { make $.list($/) }
    method simple_selector($/) { make $.node($/) }

    method pseudo($/)   { make $.node($/) }
    method function($/) { make $.node($/) }

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
