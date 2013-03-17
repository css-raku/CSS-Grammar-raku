use v6;

# rules for constructing ASTs for CSS::Grammar

class CSS::Grammar::Actions {
    use CSS::Grammar::AST::Info;
    use CSS::Grammar::AST::Token;

    has Int $.line_no is rw = 1;
    # variable encoding - not yet supported
    has $.encoding is rw = 'UTF-8';

    # accumulated warnings
    has @.warnings;

    method token(Mu $ast, :$skip, :$type, :$units) {
        $ast
            does CSS::Grammar::AST::Token
            unless $ast.can('type');

        $ast.skip = $skip if defined $skip;
        $ast.type = $type if defined $type;
        $ast.units = $units if defined $units;

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

    method at_rule($/) {
        my %terms = $.node($/);
        %terms<@> = $0.Str.lc;
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
            %unesc{$_} // (
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
        my $ord = $._from_hex($str);
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
        make $<nmreg> ?? $<nmreg>.Str !! ($<nonascii> || $<escape>).ast;
    }
    method ident($/) {
        my $pfx = $<pfx> ?? $<pfx>.Str !! '';
        make $pfx ~ $<nmstrt>.ast ~ $<nmchar>.map({$_.ast}).join('');
    }
    method name($/) {
        make $<nmchar>.map({$_.ast}).join('');
    }
    method notnum($/) { make $0.chars ?? $0.Str !! $<nonascii>.Str }
    method num($/) { make $/.Num }
    method int($/) { make $/.Int }

    method stringchar:sym<cont>($/)     { make '' }
    method stringchar:sym<escape>($/)   { make $<escape>.ast }
    method stringchar:sym<nonascii>($/) { make $<nonascii>.ast }
    method stringchar:sym<ascii>($/)    { make $/.Str }

    method single_quote($/) {make "'"}
    method double_quote($/) {make '"'}

    method string($/) {
        my Bool $skip = False;
        my $string = $<stringchar>.map({ $_.ast }).join('');
        unless ($<closing_quote>.Str) {
            $.warning('unterminated string', $string);
            $skip = True;
        }
        make $.token($string, :type('string'), :skip($skip) );
    }

    method id($/) { make $<name>.ast }
    method class($/) { make $<name>.ast }

    method url_char($/) {
        my $cap = $<escape> || $<nonascii>;
        make $cap ?? $cap.ast !! $/.Str
    }
    method url_string($/) {
        make $<string>
            ?? $<string>.ast
            !! $.token( $<url_char>.map({$_.ast}).join('') );
    }

    method url($/)  { make $<url_string>.ast }

    method color_arg($/) {
        my $arg = %<num>.ast;
        $arg = ($arg * 2.55).round
            if $<percentage>.Str;
        make $.token($arg, :type('num'), :units('4bit'));
    }

    method color_rgb($/)  { make $.node($/) }

    method prio($/) { make $0.Str.lc if $0}

    # from the TOP (CSS1 + CSS21)
    method TOP($/) { make $<stylesheet>.ast }
    method stylesheet($/) { make $.list($/) }

    method charset($/)   { make $<string>.ast }
    method import($/)    { make $.node($/) }
    method namespace($/) { make $.node($/) }

    method misplaced($/) {
        $.warning('ignoring out of sequence directive', $/.Str)
    }
    method misplaced2($/) {
        $.warning('ignoring out of sequence directive', $/.Str)
    }

    method operator($/) { make $.token($/.Str, :type('operator')) }

    # pseudos
    method pseudo:sym<element>($/) { my %node; # :first-line
                                     %node<element> = $<element>.Str;
                                     make %node;
    }
    method pseudo:sym<element2>($/) { make $.node($/) }
    method pseudo:sym<lang>($/)     { make $.node($/) }
    method pseudo:sym<function>($/) { make $.node($/) }
    method pseudo:sym<class>($/)    { make $.node($/) }

    # combinators
    method combinator:sym<adjacent>($/) { make $.token($/.Str) } # '+'
    method combinator:sym<child>($/)    { make $.token($/.Str) } # '>'
    method combinator:sym<not>($/)      { make $.token($/.Str) } # '-' css2.1
    method combinator:sym<sibling>($/)  { make $.token($/.Str) } # '~'

    # css2/css3 core - media support
    method at_rule:sym<media>($/) { make $.at_rule($/) }
    method media_rules($/)        { make $.list($/) }
    method media_list($/)         { make $.list($/) }
    method media_query($/)        { make $.list($/) }

    # css2/css3 core - page support
    method at_rule:sym<page>($/)  { make $.at_rule($/) }
    method page_pseudo($/)        { make $<ident>.ast }

    method ruleset($/)            { make $.node($/) }
    method selectors($/)          { make $.list($/) }
    method declarations($/)       { make $<declaration_list>.ast }
    method declaration_list($/)   { make $.list($/) }
    method declaration($/)        {
        my %decl = $.node($/);
        if @(%decl<expr>) {
            make %decl;
        }
        else {
            $.warning('dropping declaration', %decl<property>)
                if %decl<property>;
        }
    }

    method expr($/) { make $.list($/) }

    method expr_missing($/) {
        $.warning("incomplete declaration");
    }

    method pterm:sym<quantity>($/) {
        my ($num, $units_cap) = $/.caps;
        my $qty = $num.value.ast;

        my $type = 'num';
        my $units;

        if $units_cap && (my $units_ast = $units_cap.value.ast) {
            ($type, $units) = $units_ast.kv;
            $units = $units.lc;
        }

        make $.token($qty, :type($type), :units($units));
    }

    method units:sym<length>($/)     { make (length => $/.Str.lc) }
    method units:sym<angle>($/)      { make (angle => $/.Str.lc) }
    method units:sym<time>($/)       { make (time => $/.Str.lc) }
    method units:sym<freq>($/)       { make (freq => $/.Str.lc) }
    method units:sym<percentage>($/) { make (percentage => $/.Str.lc) }
    method dimension($/)     {
        $.warning('unknown dimensioned quantity', $/.Str);
    }
    # treat 'ex' as '1ex'; 'em' as '1em'
    method pterm:sym<emx>($/)         { make $.token(1, :units($/.Str.lc), :type('length')) }

    method aterm:sym<string>($/)      { make $.token($<string>.ast, :type('string')) }
    method aterm:sym<url>($/)         { make $.token($<url>.ast, :type('url')) }
    method aterm:sym<color_hex>($/)   {
        my $id = $<id>.ast;
        my $chars = $id.chars;
        unless $id.match(/^<xdigit>+$/)
            && ($chars == 3 || $chars == 6) {
                $.warning("bad hex color", $/.Str);
                return;
        }

        my @rgb = $chars == 3
            ?? $id.comb(/./).map({$_ ~ $_})
            !! $id.comb(/../);
        my %rgb;
        %rgb<r g b> = @rgb.map({$._from_hex( $_ )}); 
        make $.token(%rgb, :type('color'), :units('rgb'))
    }
    method aterm:sym<color_rgb>($/) { make $.token($<color_rgb>.ast, :type('color'), :units('rgb')) }
    method aterm:sym<function>($/)  { make $.token($<function>.ast, :type('function')) }
    method aterm:sym<ident>($/)     { make $.token($<ident>.ast, :type('ident')) }

    method emx($/) { make $/.Str.lc }

    method term($/) {
        if $<term> {
            my $term_ast = $<term>.ast;
            if $<unary_operator> && $<unary_operator>.Str eq '-' {
                $term_ast = $.token( - $term_ast,
                                     :units($<term>.ast.units),
                                     :type($<term>.ast.type) );
            }
            make $term_ast;
        }
    }

    method selector($/)         { make $.list($/) }
    method simple_selector($/)  { make $.list($/) }
    method attrib($/)           { make $.node($/) }
    method function($/)         { make $.node($/) }

    method attribute_selector:sym<equals>($/)    { make $/.Str }
    method attribute_selector:sym<includes>($/)  { make $/.Str }
    method attribute_selector:sym<dash>($/)      { make $/.Str }

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
    method unknown:sym<statement>($/) {$.warning('skipping', $/.Str)}
    method unknown:sym<value>($/)     {$.warning('skipping', $/.Str)}
    method unknown:sym<punct>($/)     {$.warning('skipping', $/.Str)}
    method unknown:sym<char>($/)      {$.warning('skipping', $/.Str)}

    method any($/) {}

    # utiltity methods / subs

    method _from_hex($hex) {

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
