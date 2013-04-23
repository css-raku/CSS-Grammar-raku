use v6;

# rules for constructing ASTs for CSS::Grammar

class CSS::Grammar::Actions {
    use CSS::Grammar::AST::Info;
    use CSS::Grammar::AST::Token;

    has Int $.line-no is rw = 1;
    has Int $!nl-rachet = 0;
    # variable encoding - not yet supported
    has $.encoding is rw = 'UTF-8';

    # accumulated warnings
    has @.warnings;

    method reset {
        @.warnings = ();
        $.line-no = 1;
        $!nl-rachet = 0;
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

    method at-rule($/) {
        my %terms = $.node($/);
        %terms<@> = $0.Str.lc;
        return %terms;
    }

    method list($/) {
        # make a node that contains repeatable elements
        my @terms;

        my @l = $/.can('caps') ?? ($/) !! (@$/);

        for @l {
            for $_.caps -> $cap {
                my ($key, $value) = $cap.kv;
                $value = $value.ast;
                next unless $value.defined;
                push @terms, ($key => $value);
            }
        }

        return @terms;
    }

    sub _display-string($_str) {

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
        $warning ~= ': ' ~ _display-string( $str )
            if $str.defined && $str ne '';
        $warning ~= ' - ' ~ $explanation
            if $explanation;
        $warning does CSS::Grammar::AST::Info;
        $warning.line-no = $.line-no - 1;
        push @.warnings, $warning;
    }

    method nl($/) {
        my $pos = $/.from;

        return
            if my $_backtracking = $pos <= $!nl-rachet;

        $!nl-rachet = $pos;
        $.line-no++;
    }

    method element-name($/) {make $<ident>.ast}

    method any($/) {}

    method dropped-decl:sym<forward-compat>($/) {
        $.warning('dropping term', $0.Str)
            if $0.Str.chars;
        $.warning('dropping declaration', $<property>.ast);
    }

    method dropped-decl:sym<stray-terms>($/) {
        $.warning('dropping term', $0.Str);
    }

    method dropped-decl:sym<badstring>($/) {
        my $prop = $<property>>>.ast;
        if $prop {
            $.warning('dropping declaration', $prop);
        }
        elsif $0.Str.chars {
            $.warning('dropping term', $0.Str)
        }
    }

    method dropped-decl:sym<flushed>($/) {
        $.warning('dropping term', $0.Str);
    }

    method _to-unicode($str) {
        my $ord = $._from-hex($str);
        return Buf.new( $ord ).decode( $.encoding );
    }

    method unicode($/) {
       make $._to-unicode( $0.Str );
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
    method name($/)  {
        make $<nmchar>.map({$_.ast}).join('');
    }
    method notnum($/) { make $0.chars ?? $0.Str !! $<nonascii>.Str }
    method num($/) { make $/.Num }
    method posint($/) { make $/.Int }

    method stringchar:sym<cont>($/)     { make '' }
    method stringchar:sym<escape>($/)   { make $<escape>.ast }
    method stringchar:sym<nonascii>($/) { make $<nonascii>.ast }
    method stringchar:sym<ascii>($/)    { make $/.Str }

    method single-quote($/) {make "'"}
    method double-quote($/) {make '"'}

    method string($/) {
        my $string = $<stringchar>.map({ $_.ast }).join('');
        make $.token($string, :type('string'));
    }

    method badstring($/) {
        $.warning('unterminated string', $/.Str);
    }

    method id($/) { make $<name>.ast }
    method class($/) { make $<name>.ast }

    method url-char($/) {
        my $cap = $<escape> || $<nonascii>;
        make $cap ?? $cap.ast !! $/.Str
    }
    method url-string($/) {
        my $string = $<string> || $<badstring>;
        make $string
            ?? $string.ast
            !! $.token( $<url-char>.map({$_.ast}).join('') );
    }

    method url($/)  { make $<url-string>.ast }
    method uri($/)  { make $<url>.ast }

    method color-range($/) {
        my $arg = %<num>.ast;
        $arg = ($arg * 2.55).round
            if $<percentage>.Str;
        make $.token($arg, :type('num'), :units('8bit'));
    }

    method color:sym<rgb>($/)  {
        return $.warning('usage: rgb(c,c,c) where c is 0..255 or 0%-100%')
            if $<any-args>;
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
        %rgb<r g b> = @rgb.map({$._from-hex( $_ )}); 
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

    method unicode-range:sym<from-to>($/) {
        # don't produce actual hex chars; could be out of range
        make [ $._from-hex($<from>.Str), $._from-hex($<to>.Str) ];
    }

    method unicode-range:sym<masked>($/) {
        my $mask = $/.Str;
        my $lo = $mask.subst('?', '0'):g;
        my $hi = $mask.subst('?', 'F'):g;

        # don't produce actual hex chars; could be out of range
        make [ $._from-hex($lo), $._from-hex($hi) ];
    }

    # css2/css3 core - media support
    method at-rule:sym<media>($/) { make $.at-rule($/) }
    method media-rules($/)        { make $.list($/) }
    method media-list($/)         { make $.list($/) }
    method media-query($/)        { make $.list($/) }

    # css2/css3 core - page support
    method at-rule:sym<page>($/)  { make $.at-rule($/) }
    method page-pseudo($/)        { make $<ident>.ast }

    method property($/)           { make $<property>.ast }
    method inherit($/)            { make True }
    method ruleset($/)            { make $.node($/) }
    method selectors($/)          { make $.list($/) }
    method declarations($/)       { make $<declaration-list>.ast }
    method declaration-list($/)   {
        my %declarations;

        for @$.list($/) {
            my ($_decl, $decls) = $_.kv;

            die "unexpected in declaration ast: " ~ $_decl.perl
                unless $_decl eq 'declaration';

            my $props = %$decls.delete('property-list')
                || [$decls];

            for @$props {
                my %decl = %$_;
                my $prop = %decl.delete('property')
                    // die "unable to find property in declaration";

                if %declarations.exists($prop) {
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

    method term:sym<num>($/)  { make $.token($<num>.ast, :type('num')); }
    method term:sym<qty>($/)  { make $<quantity>.ast }

    method length:sym<qty>($/) { make $.token($<num>.ast, :units($0.Str.lc), :type('length')); }
    method quantity:sym<length>($/)     { make $<length>.ast }
    # digit can be dropped, e.g. 'ex' => '1ex'; -em => '-1em'
    method length:sym<emx>($/)          { make $<emx>.ast }
    method emx($/) {
        my $num = $0 && $0.Str eq '-' ?? -1 !! +1;
        make $.token($num, :units($1.Str.lc), :type('length'))
    }

    method angle:sym<drg>($/)           { make $.token($<num>.ast, :units($0.Str.lc), :type('angle')) }
    method quantity:sym<angle>($/)      { make $<angle>.ast }

    method time($/)                     { make $.token($<num>.ast, :units($0.Str.lc), :type('time')) }
    method quantity:sym<time>($/)       { make $<time>.ast }

    method frequency:sym<k?hz>($/)      { make $.token($<num>.ast, :units($0.Str.lc), :type('frequency')) }
    method quantity:sym<frequency>($/)  { make $<frequency>.ast }

    method percentage($/)               { make $.token($<num>.ast, :units('%'), :type('percentage')) }
    method quantity:sym<percentage>($/) { make $<percentage>.ast }

    method term:sym<string>($/)   { make $.token($<string>.ast, :type('string')) }
    method term:sym<url>($/)      { make $.token($<url>.ast, :type('url')) }
    method term:sym<color>($/)    { make $<color>.ast; }
    method term:sym<function>($/) {
        make $.token($<function>.ast, :type('function'));
    }
    method term:sym<ident>($/)    {
        if $<emx> {
            # floating 'em' or 'ex'
            make $<emx>.ast;
            return;
        }
        make $.token($<ident>.ast, :type('ident'))
    }

    method universal($/)          { make $/.Str }
    method selector($/)           { make $.list($/) }
    method simple-selector($/)    { make $.list($/) }
    method attrib($/)             { make $.list($/) }

    method any-function($/)       {
        my %ast = $.node($/);
        %ast<args> //= []; # indicates an empty argument list
        make $.token(%ast, :type('function'));
    }

    method pseudo-function:sym<lang>($/)             {
        return $.warning('usage: lang(ident)')
            if $<any-args>;
        make {ident => 'lang', args => $.list($/)}
    }

    method any-pseudo-func($/)             {
        $.warning('unknown pseudo-function', $<ident>.ast.lc);
    }

    method attribute-selector:sym<equals>($/)    { make $/.Str }
    method attribute-selector:sym<includes>($/)  { make $/.Str }
    method attribute-selector:sym<dash>($/)      { make $/.Str }

    method unclosed-comment($/) {
        $.warning('unclosed comment at end of input');
    }

    method unclosed-paren($/) {
        $.warning("missing closing ')'");
    }

    method end-block($/) {
        $.warning("no closing '}'")
            unless $<closing-paren>;
    }

    # todo: warnings can get a bit too verbose here
    method unknown:sym<statement>($/) {$.warning('dropping', $/.Str)}
    method unknown:sym<flushed>($/)   {$.warning('dropping', $/.Str)}
    method unknown:sym<punct>($/)     {$.warning('dropping', $/.Str)}
    method unknown:sym<char>($/)      {$.warning('dropping', $/.Str)}

    # utiltity methods / subs

    method _from-hex($hex) {

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
