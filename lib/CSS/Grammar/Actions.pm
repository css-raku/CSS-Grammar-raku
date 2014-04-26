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

    method token(Mu $ast, :$type, :$units) {

        return unless $ast.defined;

        $ast
            does CSS::Grammar::AST::Token
            unless $ast.can('type');

        $ast.type = $type   if $type.defined;
        $ast.units = $units if $units.defined;

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
                if %terms{$key}:exists {
                    $.warning("repeated term " ~ $key, $value);
                    return Any;
                }

                $value = $value.ast
                    // ($capture && $capture eq $key
                        ?? ~$value
                        !! next);

                %terms{$key} = $value;
            }
        }

        return %terms;
    }

    method at-rule($/) {
        my %terms = $.node($/);
        %terms<@> = (~$0).lc;
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
                        ?? ~$value
                        !! next);

		# dumbed down for json compatibility
                push @terms, {$key => $value};
            }
        }

        return @terms;
    }

    sub _display-string($_str) {

        my $str = $_str.chomp.trim;
        $str = $str.subst(/[\s|\t|\n|\r|\f]+/, ' '):g;

        [~] $str.comb.map({
                $_ eq "\\"                  ?? '\\'
                    !! /<[\t \s \!..\~]>/   ?? $_   
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

    method element-name($/)             { make $<ident>.ast }

    method distance-units:sym<abs>($/)  { make $.token( ~($/).lc, :type<length> ) }
    method distance-units:sym<font>($/) { make $.token( ~($/).lc, :type<length> ) }

    method any($/) {}

    method dropped-decl:sym<forward-compat>($/) {
        $.warning('dropping term', ~$0)
            if $0;
        $.warning('dropping term', ~$1)
            if $1;
        $.warning('dropping declaration', $<property>.ast)
	    if $<property>;
    }

    method dropped-decl($/) {

	$.warning('dropping term', ~$<any>)
	    if $<any>;

        if my $prop = $<property>>>.ast {
            $.warning('dropping declaration', $prop);
        }
    }

    method dropped-decl:sym<flushed>($/) {
        $.warning('dropping term', ~$0);
    }

    method _to-unicode($hex-str) {
	my $char;
	try {
	    $char = chr( :16($hex-str) );
	    CATCH {
		default {
		    $.warning('invalid unicode code-point', 'U+' ~ $hex-str.uc );
		    $char = chr(0xFFFD); # �
		}
	    }
	}
	return $char;
    }

    method unicode($/) {
       make $._to-unicode( ~$0 );
    }

    method regascii($/) { make ~$/ }
    method nonascii($/) { make ~$/ }

    method escape($/)   { make $<char>.ast }

    method nmstrt($/)   { make $<char> ?? $<char>.ast !! ~$0}

    method nmchar($/)   { make $<char>.ast }

    method nmreg($/)    { make ~$/ }

    method ident($/) {
        my $pfx = $<pfx> ?? ~$<pfx> !! '';
        my $ident = [~] ($pfx, $<nmstrt>.ast, $<nmchar>>>.ast);
        make $ident.lc;
    }

    method name($/)   { make [~] $<nmchar>>>.ast; }
    method num($/)    { make $0 ?? $/.Rat !! $/.Int}

    method stringchar:sym<cont>($/)     { make '' }
    method stringchar:sym<escape>($/)   { make $<escape>.ast }
    method stringchar:sym<nonascii>($/) { make $<nonascii>.ast }
    method stringchar:sym<ascii>($/)    { make ~$/ }

    method single-quote($/) { make "'" }
    method double-quote($/) { make '"' }

    method _string($/) {
        my $string = [~] $<stringchar>>>.ast;
        make $.token($string, :type<string>);
    }

    method string:sym<single-q>($/) { $._string($/) }

    method string:sym<double-q>($/) { $._string($/) }

    method badstring($/) {
        $.warning('unterminated string', ~$/);
    }

    method id($/)    { make $<name>.ast }

    method class($/) { make $<name>.ast }

    method bare-url-char($/) {
        make $<char> ?? $<char>.ast !! ~$/
    }

    method url($/)   { make [~] $<string>>>.ast }

    # uri - synonym for url?
    method uri($/)   { make $<url>.ast }

    method color-range($/) {
        my $range = $<num>.ast;
        $range *= 2.55
            if ~$<percentage>;

        # clip out-of-range colors, see
        # http://www.w3.org/TR/CSS21/syndata.html#value-def-color
        $range = 0 if $range < 0;
        $range = 255 if $range > 255;

        make $.token($range.round, :type<num>, :units<8bit>);
    }

    method color:sym<rgb>($/)  {
        return $.warning('usage: rgb(c,c,c) where c is 0..255 or 0%-100%')
            if $<any-args>;
        make $.token($.node($/), :type<color>, :units<rgb>);
    }

    method color:sym<hex>($/)   {
        my $id = $<id>.ast;
        my $chars = $id.chars;

        return $.warning("bad hex color", ~$/)
            unless $id.match(/^<xdigit>+$/)
            && ($chars == 3 || $chars == 6);

        my @rgb-vals = $chars == 3
            ?? $id.comb(/./).map({$^hex-digit ~ $^hex-digit})
            !! $id.comb(/../);

        my %rgb = <r g b> Z=> @rgb-vals.map({ :16($_) }); 
        make $.token(%rgb, :type<color>, :units<rgb>);
    }

    method prio($/) {
        return $.warning("dropping term", ~$/)
            if $<any> || !$0;

        make (~$0).lc
    }

    # from the TOP (CSS1 + CSS21 + CSS3)
    method TOP($/) { make $<stylesheet>.ast }
    method stylesheet($/) { make $.list($/) }

    method charset($/)   { make $<string>.ast }
    method import($/)    { make $.node($/) }
    method namespace($/) { make $.node($/) }

    method misplaced($/) {
        $.warning('ignoring out of sequence directive', ~$/)
    }

    method operator($/) { make $.token(~$/, :type<operator>) }

    # pseudos
    method pseudo:sym<element>($/)  { make {element => (~$<element>).lc} }
    method pseudo:sym<function>($/) { make $.node($/) }
    method pseudo:sym<class>($/)    { make $.node($/) }

    # combinators
    method combinator:sym<adjacent>($/) { make $.token('+') }
    method combinator:sym<child>($/)    { make $.token('>') }
    method combinator:sym<not>($/)      { make $.token('-') } # css21

    method unicode-range:sym<from-to>($/) {
        # don't produce actual hex chars; could be out of range
        make [ :16( ~$<from> ), :16( ~$<to> ) ];
    }

    method unicode-range:sym<masked>($/) {
        my $mask = ~$<mask>;
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
            my ($tk, $decls) = .kv; 

            die "unexpected in declaration ast: " ~ $tk
                unless $tk eq 'declaration';

            my $prio = $decls<prio>;
            my $props = $decls<property-list>
                || [$decls];

            for @$props -> %decl {
                %decl<prio> = $prio if $prio;
                my $prop = %decl<property>:delete
                    // die "unable to find property in declaration";

                if %declarations{$prop}:exists {
                    # override the previous declaration unless it's more !important
                    next if %declarations{$prop}<prio> && ! %decl<prio>;
                }

                %declarations{ $prop } = %decl;
            }
        }

        make %declarations;
    }

    method declaration:sym<base>($/)        {
        return $.warning('dropping declaration', $<property>.ast)
            if !$<expr>.caps
            || $<expr>.caps.grep({! .value.ast.defined});

        make $.node($/);
    }

    method expr($/)           { make $.list($/) }
    method term:sym<base>($/) { make $<term>.ast }

    method term1:sym<dimension>($/)  { make $<dimension>.ast }
    method term1:sym<percentage>($/) { make $<percentage>.ast }

    method length:sym<dim>($/) { make $.token($<num>.ast, :units($<units>.ast), :type<length>); }
    method dimension:sym<length>($/) { make $<length>.ast }
    method length:sym<rel-font-unit>($/) {
        my $num = $0 && ~$0 eq '-' ?? -1 !! +1;
        make $.token($num, :units( ~($1).lc), :type<length>)
    }

    method angle-units($/)              { make $.token( ~($/).lc, :type<angle> ) }
    method angle:sym<dim>($/)           { make $.token($<num>.ast, :units($<units>.ast), :type<angle>) }
    method dimension:sym<angle>($/)     { make $<angle>.ast }

    method time-units($/)               { make $.token( ~($/).lc, :type<time> ) }
    method time:sym<dim>($/)            { make $.token($<num>.ast, :units($<units>.ast), :type<time>) }
    method dimension:sym<time>($/)      { make $<time>.ast }

    method frequency-units($/)          { make $.token( ~($/).lc, :type<frequency> ) }
    method frequency:sym<dim>($/)       { make $.token($<num>.ast, :units($<units>.ast), :type<frequency>) }
    method dimension:sym<frequency>($/) { make $<frequency>.ast }

    method percentage($/)               { make $.token($<num>.ast, :units<%>, :type<percentage>) }

    method term1:sym<string>($/)   { make $.token($<string>.ast, :type<string>) }
    method term1:sym<url>($/)      { make $.token($<url>.ast, :type<url>) }
    method term1:sym<color>($/)    { make $<color>.ast; }
    method term2:sym<function>($/) { make $<function>.ast }

    # temporary work-around for RT120146 Oct 13
    method term2:sym<tmp>($/)      { make $<num>
                                        ?? $.token($<num>.ast, :type<num>)
                                        !! $.token($<ident>.ast, :type<ident>)
    }

    method term2:sym<num>($/)      { make $.token($<num>.ast, :type<num>); }
    method term2:sym<ident>($/)    { make $.token($<ident>.ast, :type<ident>) }

    method selector($/)           { make $.list($/) }

    method universal($/)          { make {element-name => ~$/} }
    method qname($/)              { make $.node($/) }
    method simple-selector($/)    { make $.list($/) }

    method attrib($/)             { make $.list($/) }

    method any-function($/) {
	return $.warning('skipping function arguments', ~$<any-arg>)
	    if $<any-arg>;
        make $.list($/, :type<function>);
    }

    method pseudo-function:sym<lang>($/) {
        return $.warning('usage: lang(ident)')
            if $<any-args>;
        make {ident => 'lang', args => $.list($/)}
    }

    method unknown-pseudo-func($/) {
        $.warning('unknown pseudo-function', $<ident>.ast);
    }

    method attribute-selector:sym<equals>($/)    { make ~$/ }
    method attribute-selector:sym<includes>($/)  { make ~$/ }
    method attribute-selector:sym<dash>($/)      { make ~$/ }

    method end-block($/) {
        $.warning("no closing '}'")
            unless $<closing-paren>;
    }

    method unclosed-comment($/) {
        $.warning('unclosed comment at end of input');
    }

    method unclosed-paren-square($/) {
        $.warning("no closing ']'");
    }

    method unclosed-paren-round($/) {
        $.warning("no closing ')'");
    }

    method unknown($/) {
        $.warning('dropping', ~$/)
    }

}
