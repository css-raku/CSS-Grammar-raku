use v6;

# rules for constructing ASTs for CSS::Grammar

class CSS::Grammar::Actions {
    use CSS::Grammar::AST::Info;
    use CSS::Grammar::AST::Token;

    has Int $.line_no is rw = 1;
    has Int $!nl_highwater = 0;
    # variable encoding - not yet supported
    has $.encoding is rw = 'UTF-8';

    # accumulated warnings
    has @.warnings;

    method reset {
        @.warnings = ();
        $.line_no = 1;
        $!nl_highwater = 0;
    }

    method token(Mu $ast, :$skip, :$type, :$units) {

        return unless $ast.defined;

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
            next unless $value.defined;
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
            next unless $value.defined;
            push @terms, ($key => $value);
        }

        return @terms;
    }

    sub _display_string($_str) {

        my $str = $_str.chomp.trim;
        $str = $str.subst(/[\s|\t|\n|\r|\f]+/, ' '):g;

        $str.split('').map({
            $_ eq "\\"               ?? '\\'
            !! /<[\t\o40 \!..\~]>/   ?? $_   
            !! $_.ord.fmt("\\x[%x]")
       }).join('');
    }

    method warning ($message, $str?, $explanation?) {
        my $warning = $message;
        $warning ~= ': ' ~ _display_string( $str )
            if $str.defined && $str ne '';
        $warning ~= ' - ' ~ $explanation
            if $explanation;
        $warning does CSS::Grammar::AST::Info;
        $warning.line_no = $.line_no;
        push @.warnings, $warning;
    }

    method nl($/) {
        my $pos = $/.from;

        return
            if my $_backtracking = $pos <= $!nl_highwater;

        $!nl_highwater = $pos;
        $.line_no++;
    }

    method element_name($/) {make $<ident>.ast}

    method any($/) {}

    method dropped_decl:sym<forward_compat>($/) {
        $.warning('dropping term', $0.Str)
            if $0.Str.chars;
        $.warning('dropping declaration', $<property>.ast);
    }

    method dropped_decl:sym<stray_terms>($/) {
        $.warning('dropping term', $0.Str);
    }

    method dropped_decl:sym<badstring>($/) {
        my $prop = $<property>>>.ast;
        if $prop {
            $.warning('dropping declaration', $prop);
        }
        elsif $0.Str.chars {
            $.warning('dropping term', $0.Str)
        }
    }

    method dropped_decl:sym<flushed>($/) {
        $.warning('dropping term', $0.Str);
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
        my $ident =  $<nmstrt>.ast ~ $<nmchar>.map({$_.ast}).join('');
        make $pfx ~ $ident.lc;
    }
    method name($/) {
        make $<nmchar>.map({$_.ast}).join('');
    }
    method notnum($/) { make $0.chars ?? $0.Str !! $<nonascii>.Str }
    method num($/) { make $/.Num }
    method posint($/) { make $/.Int }

    method stringchar:sym<cont>($/)     { make '' }
    method stringchar:sym<escape>($/)   { make $<escape>.ast }
    method stringchar:sym<nonascii>($/) { make $<nonascii>.ast }
    method stringchar:sym<ascii>($/)    { make $/.Str }

    method single_quote($/) {make "'"}
    method double_quote($/) {make '"'}

    method string($/) {
        my $string = $<stringchar>.map({ $_.ast }).join('');
        make $.token($string, :type('string'));
    }

    method badstring($/) {
        $.warning('unterminated string', $/.Str);
    }

    method id($/) { make $<name>.ast }
    method class($/) { make $<name>.ast }

    method url_char($/) {
        my $cap = $<escape> || $<nonascii>;
        make $cap ?? $cap.ast !! $/.Str
    }
    method url_string($/) {
        my $string = $<string> || $<badstring>;
        make $string
            ?? $string.ast
            !! $.token( $<url_char>.map({$_.ast}).join('') );
    }

    method url($/)  { make $<url_string>.ast }
    method uri($/)  { make $<url>.ast }

    method color-range($/) {
        my $arg = %<num>.ast;
        $arg = ($arg * 2.55).round
            if $<percentage>.Str;
        make $.token($arg, :type('num'), :units('8bit'));
    }

    method color:sym<rgb>($/)  {
        return $.warning('usage: rgb(c,c,c) where c is 0..255 or 0%-100%')
            unless $<ok>;
        make $.token($.node($/), :type<color>, :units<rgb>);
    }
    method color:sym<hex>($/)   {
        my $id = $<id>.ast;
        my $chars = $id.chars;

        return $.warning("bad hex color", $/.Str)
            unless $id.match(/^<xdigit>+$/)
            && ($chars == 3 || $chars == 6);

        my @rgb = $chars == 3
            ?? $id.comb(/./).map({$_ ~ $_})
            !! $id.comb(/../);
        my %rgb;
        %rgb<r g b> = @rgb.map({$._from_hex( $_ )}); 
        make $.token(%rgb, :type<color>, :units<rgb>);
    }

    method prio($/) {
        my ($any) = $<any>.list;
        if $any || !$0 {
            $.warning("dropping term", $/.Str);
            return;
        }

        make $0.Str.lc
    }

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
                                     %node<element> = $<element>.Str.lc;
                                     make %node;
    }
    method pseudo:sym<element2>($/) { make $.node($/) }
    method pseudo:sym<function>($/) { make $.node($/) }
    method pseudo:sym<class>($/)    { make $.node($/) }

    # combinators
    method combinator:sym<adjacent>($/) { make $.token($/.Str) } # '+'
    method combinator:sym<child>($/)    { make $.token($/.Str) } # '>'
    method combinator:sym<not>($/)      { make $.token($/.Str) } # '-' css2.1
    method combinator:sym<sibling>($/)  { make $.token($/.Str) } # '~'

    method unicode_range:sym<from_to>($/) {
        # don't produce actual hex chars; could be out of range
        make [ $._from_hex($<from>.Str), $._from_hex($<to>.Str) ];
    }

    method unicode_range:sym<masked>($/) {
        my $mask = $/.Str;
        my $lo = $mask.subst('?', '0'):g;
        my $hi = $mask.subst('?', 'F'):g;

        # don't produce actual hex chars; could be out of range
        make [ $._from_hex($lo), $._from_hex($hi) ];
    }

    # css2/css3 core - media support
    method at_rule:sym<media>($/) { make $.at_rule($/) }
    method media_rules($/)        { make $.list($/) }
    method media_list($/)         { make $.list($/) }
    method media_query($/)        { make $.list($/) }

    # css2/css3 core - page support
    method at_rule:sym<page>($/)  { make $.at_rule($/) }
    method page_pseudo($/)        { make $<ident>.ast }

    method property($/)           { make $<property>.ast }
    method inherit($/)            { make True }
    method ruleset($/)            { make $.node($/) }
    method selectors($/)          { make $.list($/) }
    method declarations($/)       { make $<declaration_list>.ast }
    method declaration_list($/)   {
        my %declarations;

        for @$.list($/) {
            for @$_ {
                my ($_decl, $declaration) = $_.kv;

                die "unexpected in declaration ast: " ~ $_decl.perl
                    unless $_decl eq 'declaration';

                my %decl = %$declaration;
                my $prop = %decl.delete('property')
                    // die "unable to find property in declaration";

                if %declarations.exists($prop) {
                    $.warning('duplicate declaration', $prop);
                    # drop the previous declaration unless it's !important
                    next if %declarations{$prop}<prio> && ! %decl<prio>;
                }

                %declarations{ $prop } = %decl;
            }
        }

        make %declarations;
    }
    method declaration:sym<raw>($/)        {
        if !$<expr>.caps || $<expr>.caps.grep({! $_.value.ast.defined}) {
            $.warning('dropping declaration', $<property>.ast);
            return;
        }

        make $.node($/);
    }

    method expr($/) { make $.list($/) }

    method pterm:sym<num>($/) { make $.token($<num>.ast, :type('num')); }
    method pterm:sym<qty>($/) { make $<quantity>.ast }

    method length($/) { make $.token($<num>.ast, :units($0.Str.lc), :type('length')); }
    method quantity:sym<length>($/)     { make $<length>.ast }

    method angle($/)                    { make $.token($<num>.ast, :units($0.Str.lc), :type('angle')) }
    method quantity:sym<angle>($/)      { make $<angle>.ast }

    method time($/)                     { make $.token($<num>.ast, :units($0.Str.lc), :type('time')) }
    method quantity:sym<time>($/)       { make $<time>.ast }

    method freq($/)                     { make $.token($<num>.ast, :units($0.Str.lc), :type('freq')) }
    method quantity:sym<freq>($/)       { make $<freq>.ast }

    method percentage($/)               { make $.token($<num>.ast, :units('%'), :type('percentage')) }
    method quantity:sym<percentage>($/) { make $<percentage>.ast }


    # treat 'ex' as '1ex'; 'em' as '1em'
    method pterm:sym<emx>($/)        { make $.token(1, :units($/.Str.lc), :type('length')) }

    method aterm:sym<string>($/)     { make $.token($<string>.ast, :type('string')) }
    method aterm:sym<url>($/)        { make $.token($<url>.ast, :type('url')) }
    method aterm:sym<color>($/)      { make $<color>.ast; }
    method aterm:sym<function>($/)   {
        make $.token($<function>.ast, :type('function'))
            if $<function>;
    }
    method aterm:sym<ident>($/)      { make $.token($<ident>.ast, :type('ident')) }

    method emx($/) { make $/.Str.lc }

    method term($/) {
        if $<term> {
            my $term_ast = $<term>.ast;
            if $<unary_operator> && $<unary_operator>.Str eq '-' {
                my $units = $term_ast.can('units') && $term_ast.units;
                my $type = $term_ast.can('type') && $term_ast.type;
                $term_ast = $.token( - $term_ast, :units($units), :type($type) );
            }
            make $term_ast;
        }
    }

    method selector($/)          { make $.list($/) }
    method simple_selector($/)   { make $.list($/) }
    method attrib($/)            { make $.node($/) }

    method function:sym<attr>($/)             {
        return $.warning('usage: attr( attribute-name <type-or-unit>? [, <fallback> ]? )')
            if $<bad_args>;
        make {ident => 'attr', args => $.list($/)}
    }
    method function:sym<counter>($/) {
        return $.warning('usage: counter(ident [, ident [,...] ])')
            if $<bad_args>;
        make {ident => 'counter', args => $.list($/)}
    }
    method function:sym<counters>($/) {
        return $.warning('usage: counters(ident [, "string"])')
            if $<bad_args>;
        make {ident => 'counters', args => $.list($/)}
    }
    method pseudo_function:sym<lang>($/)             {
        return $.warning('usage: lang(ident)')
            if $<bad_args>;
        make {ident => 'lang', args => $.list($/)}
    }
    method unknown_function($/)             {
        $.warning('unknown function', $<ident>.ast.lc);
    }
    method unknown_pseudo_func($/)             {
        $.warning('unknown pseudo-function', $<ident>.ast.lc);
    }

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
    method unknown:sym<statement>($/) {$.warning('dropping', $/.Str)}
    method unknown:sym<flushed>($/)   {$.warning('dropping', $/.Str)}
    method unknown:sym<punct>($/)     {$.warning('dropping', $/.Str)}
    method unknown:sym<char>($/)      {$.warning('dropping', $/.Str)}

    # utiltity methods / subs

    method _from_hex($hex) {

        my $result = 0;

        for $hex.split('') {

            my $hex_digit;

            if ($_ ge '0' && $_ le '9') {
                $hex_digit = $_.Int;
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
