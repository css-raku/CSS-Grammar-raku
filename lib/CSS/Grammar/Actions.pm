use v6;

# rules for constructing ASTs for CSS::Grammar, CSS::Grammar::CSS1,
# CSS::Grammar::CSS21 and CSS::Grammar::CSS3

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

    method node($/, :$capture?) {
        my %terms;

        # unwrap Parcels
        my @l = $/.can('caps')
            ?? ($/)
            !! $/.grep({ .defined });

        for @l {
            for .caps -> $cap {
                my ($key, $value) = $cap.kv;
                if %terms.exists($key) {
                    $.warning("repeated term " ~ $key ~ ":", $value);
                    return Any;
                }

                $value = $value.ast
                    // ($capture && $capture eq $key
                        ?? $value.Str
                        !! next);

                %terms{$key} = $value;
            }
        }

        return %terms;
    }

    method at-rule($/) {
        my %terms = $.node($/);
        %terms<@> = $0.Str.lc;
        return %terms;
    }

    method list($/, :$capture?) {
        # make a node that contains repeatable elements
        my @terms;

        # unwrap Parcels
        my @l = $/.can('caps')
            ?? ($/)
            !! $/.grep({ .defined });

        for @l {
            for .caps -> $cap {
                my ($key, $value) = $cap.kv;
                $value = $value.ast
                    // ($capture && $capture eq $key
                        ?? $value.Str
                        !! next);

                push @terms, ($key => $value);
            }
        }

        return @terms;
    }

    sub _display-string($_str) {

        my $str = $_str.chomp.trim;
        $str = $str.subst(/[\s|\t|\n|\r|\f]+/, ' '):g;

        [~] $str.split('').map({
                $_ eq "\\"               ?? '\\'
                    !! /<[\t\o40 \!..\~]>/   ?? $_   
                    !! .ord.fmt("\\x[%x]")
            });
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

    method distance-units:sym<abs>($/) { make $.token( $/.Str.lc, :type<length> ) }
    method distance-units:sym<font>($/) { make $.token( $/.Str.lc, :type<length> ) }

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
        my $ord = :16($str);
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
        my $ident = [~] ($<nmstrt>.ast, $<nmchar>>>.ast);
        make $pfx ~ $ident.lc;
    }
    method name($/)  {
        make [~] $<nmchar>>>.ast;;
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

    method _string($/) {
        my $string = [~] $<stringchar>>>.ast;
        make $.token($string, :type<string>);
    }
    method string:sym<single-q>($/) { $._string($/) }
    method string:sym<double-q>($/) { $._string($/) }

    method badstring($/) {
        $.warning('unterminated string', $/.Str);
    }

    method id($/) { make $<name>.ast }
    method class($/) { make $<name>.ast }

    method url-chars($/) {
        make $<char> ?? $<char>.ast !! $/.Str
    }
    method url:sym<string>($/) { make $<string>.ast }
    method url:sym<unquoted>($/) {
        make $.token( [~] $<url-chars>>>.ast );
    }

    # uri - synonym for url?
    method uri($/)  { make $<url>.ast }

    method color-range($/) {
        my $arg = %<num>.ast;
        $arg = ($arg * 2.55).round
            if $<percentage>.Str;

        # clip out-of-range colors, see
        # http://www.w3.org/TR/CSS21/syndata.html#value-def-color
        $arg = 0 if $arg < 0;
        $arg = 255 if $arg > 255;

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
        %rgb<r g b> = @rgb.map({ :16($_) }); 
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

    # from the TOP (CSS1 + CSS21 + CSS3)
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
    method pseudo:sym<element>($/)  { make {element => $<element>.Str.lc} }
    method pseudo:sym<function>($/) { make $.node($/) }
    method pseudo:sym<class>($/)    { make $.node($/) }

    # combinators
    method combinator:sym<adjacent>($/) { make $.token('+') }
    method combinator:sym<child>($/)    { make $.token('>') }
    method combinator:sym<not>($/)      { make $.token('-') } # css21

    method unicode-range:sym<from-to>($/) {
        # don't produce actual hex chars; could be out of range
        make [ :16($<from>.Str), :16($<to>.Str) ];
    }

    method unicode-range:sym<masked>($/) {
        my $mask = $/.Str;
        my $lo = $mask.subst('?', '0'):g;
        my $hi = $mask.subst('?', 'F'):g;

        # don't produce actual hex chars; could be out of range
        make [ :16($lo), :16($hi) ];
    }

    # css21/css3 core - media support
    method at-rule:sym<media>($/) { make $.at-rule($/) }
    method media-rules($/)        { make $.list($/) }
    method media-list($/)         { make $.list($/) }
    method media-query($/)        { make $.list($/) }

    # css21/css3 core - page support
    method at-rule:sym<page>($/)  { make $.at-rule($/) }
    method page-pseudo($/)        { make $<ident>.ast }

    method property($/)           { make $<property>.ast }
    method ruleset($/)            { make $.node($/) }
    method selectors($/)          { make $.list($/) }
    method declarations($/)       { make $<declaration-list>.ast }
    method declaration-list($/)   {
        my %declarations;

        for @$.list($/) {
            my ($_decl, $decls) = .kv;

            die "unexpected in declaration ast: " ~ $_decl.perl
                unless $_decl eq 'declaration';

            my $prio = %$decls.delete('prio');

            my $props = %$decls.delete('property-list')
                || [$decls];

            for @$props {
                my %decl = %$_;
                %decl<prio> = $prio if $prio;
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

    method declaration:sym<base>($/)        {
        if !$<expr>.caps || $<expr>.caps.grep({! .value.ast.defined}) {
            $.warning('dropping declaration', $<property>.ast);
            return;
        }

        make $.node($/);
    }

    method expr($/) { make $.list($/) }

    method term:sym<num>($/)        { make $.token($<num>.ast, :type('num')); }
    method term:sym<dimension>($/)  { make $<dimension>.ast }
    method term:sym<percentage>($/) { make $<percentage>.ast }

    method length:sym<dim>($/) { make $.token($<num>.ast, :units($<units>.ast), :type<length>); }
    method dimension:sym<length>($/)     { make $<length>.ast }
    method length:sym<rel-font-unit>($/) {
        my $num = $0 && $0.Str eq '-' ?? -1 !! +1;
        make $.token($num, :units($1.Str.lc), :type<length>)
    }

    method angle-units($/)              { make $.token( $/.Str.lc, :type<angle> ) }
    method angle:sym<dim>($/)           { make $.token($<num>.ast, :units($<units>.ast), :type('angle')) }
    method dimension:sym<angle>($/)     { make $<angle>.ast }

    method time-units($/)               { make $.token( $/.Str.lc, :type<time> ) }
    method time:sym<dim>($/)            { make $.token($<num>.ast, :units($<units>.ast), :type('time')) }
    method dimension:sym<time>($/)      { make $<time>.ast }

    method frequency-units($/)          { make $.token( $/.Str.lc, :type<frequency> ) }
    method frequency:sym<dim>($/)       { make $.token($<num>.ast, :units($<units>.ast), :type<frequency>) }
    method dimension:sym<frequency>($/) { make $<frequency>.ast }

    method percentage($/)               { make $.token($<num>.ast, :units('%'), :type('percentage')) }

    method term:sym<string>($/)   { make $.token($<string>.ast, :type('string')) }
    method term:sym<url>($/)      { make $.token($<url>.ast, :type('url')) }
    method term:sym<color>($/)    { make $<color>.ast; }
    method term:sym<function>($/) { make $<function>.ast }
    method term:sym<ident>($/)    {
        make $.token($<ident>.ast, :type('ident'))
    }

    method selector($/)           { make $.list($/) }

    method universal($/)          { make {element-name => $/.Str} }
    method qname($/)              { make $.node($/) }
    method simple-selector($/)    { make $.list($/) }

    method attrib($/)             { make $.list($/) }

    method function($/)       {
        make $.token( $.list($/), :type('function'));
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

    method unclosed-paren-square($/) {
        $.warning("no closing ']'");
    }

    method unclosed-paren-round($/) {
        $.warning("no closing ')'");
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
}
