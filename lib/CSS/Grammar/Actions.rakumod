use v6;

# rules for constructing ASTs for CSS::Grammar, CSS::Grammar::CSS1,
# CSS::Grammar::CSS21 and CSS::Grammar::CSS3

class X::CSS is Exception { }

class X::CSS::Ignored is X::CSS {
    sub display-string(Str $str is copy --> Str) {

        $str = $str.chomp.trim;
        $str ~~ s:g/[\s|\t|\n|\r|\f]+/ /;

        [~] $str.comb.map: {
                    /<[ \\ \t \s \!..\~ ]>/
                        ?? $_  
                        !! .ord.fmt("\\x[%x]")
            };
    }

    has Str $.message is required;
    has Str $!str;
    has Str $!explanation;

    submethod TWEAK(:$str, :$explanation ) {
        $!str = .&display-string with $str;
        $!explanation = .&display-string with $explanation;
    }
    method message {
        my $warning = $!message;
        $warning ~= ': ' ~ $_ with $!str;
        $warning ~= ' - ' ~ $_ with $!explanation;
        $warning;
    }
    method Str {$.message}
}


class CSS::Grammar::Actions {
    use CSS::Grammar::AST;
    use CSS::Grammar::Defs :CSSObject, :CSSValue, :CSSUnits, :CSSSelector;

    # variable encoding - not yet supported
    has Str $.encoding is rw = 'UTF-8';
    has Bool $.lax = False;
    has Bool $.xml = False;

    method build handles<token node list at-rule> {
        CSS::Grammar::AST;
    }

    # accumulated warnings
    has X::CSS::Ignored @.warnings;

    method reset {
        @.warnings = [];
    }

    method pseudo-func( Str $ident, $expr --> Pair) is DEPRECATED<ast.pseudo-func> {
        my %ast = :$ident, :$expr;
        $.build.token( %ast, :type(CSSSelector::PseudoFunction) );
    }

    method warning(Str:D() $message, Str $str?, Str $explanation?) {
        @.warnings.push: X::CSS::Ignored.new( :$message, :$str, :$explanation);
    }

    method eol($/) { }

    method element-name($/)           {
        make $.build.token( $!xml ?? $_ !! .lc, :type(CSSValue::ElementNameComponent))
            given $<Id>.ast;
    }

    method length-units:sym<abs>($/)  { make $/.lc }
    method length-units:sym<font>($/) { make $/.lc }

    method any($/) {}

    method dropped-decl:sym<forward-compat>($/) {
        $.warning('dropping term', .Str) with $0 // $1;
        $.warning('dropping declaration', .ast)
            with $<property>;
    }

    method dropped-decl($/) {
        $.warning('dropping term', ~$<any>)
            if $<any>;
        $.warning('dropping declaration', .ast)
            with $<property>;
    }

    method !to-unicode($hex-str --> Str) {
        my $char  = chr( :16($hex-str) );
        CATCH {
            default {
                $.warning('invalid unicode code-point', 'U+' ~ $hex-str.uc );
                $char = chr(0xFFFD); # �
            }
        }
        $char;
    }

    method unicode($/)  { make self!to-unicode(~$0) }

    method regascii($/) { make ~$/ }
    method nonascii($/) { make ~$/ }

    method escape($/)   { make do with $<char> { .ast } else { '' } }

    method nmstrt($/)   { make $<char> ?? $<char>.ast !! ~$0}

    method nmchar($/)   { make $<char>.ast }

    method nmreg($/)    { make ~$/ }

    method Id($/) {
        my $pfx = $<pfx> ?? ~$<pfx> !! '';
        make [~] $pfx, $<nmstrt>.ast, @<nmchar>».ast.Slip;
    }

    method Ident($/) {
        make $<Id>.ast.lc;
    }

    method name($/)  {
	my Str $name = [~] @<nmchar>».ast;
	make $.build.token( $name, :type(CSSValue::NameComponent));
    }
    method num($/)   {
        my $num = $/.Rat;
        $num .= Int if $num %% 1;
        make $.build.token($num, :type(CSSValue::NumberComponent));
    }
    method uint($/)  { make $/.Int }
    method op($/)    { make make $.build.token($<c>.lc, :type(CSSValue::OperatorComponent));  }

    method stringchar:sym<escape>($/)   { make $<escape>.ast }
    method stringchar:sym<nonascii>($/) { make $<nonascii>.ast }
    method stringchar:sym<ascii>($/)    { make ~$/ }

    method single-quote($/) { make "'" }
    method double-quote($/) { make '"' }

    method !string-token($/ --> Pair) {
        my $string = [~] $<stringchar>>>.ast;
        make $.build.token($string, :type(CSSValue::StringComponent));
    }

    proto method string {*}
    method string:sym<single-q>($/) { self!string-token($/) }

    method string:sym<double-q>($/) { self!string-token($/) }

    method badstring($/) {
        $.warning('unterminated string', ~$/);
    }

    method id($/)    { make $.build.token( $<name>.ast, :type(CSSSelector::Id)) }

    method class($/) { make $.build.token( $<name>.ast, :type(CSSSelector::Class)) }

    method url-unquoted-char($/) {
        make $<char> ?? $<char>.ast !! ~$/
    }

    method url-unquoted($/) {
        make [~] $<url-unquoted-char>>>.ast;
    }

    method url($/)   {
        make $.build.token( $<url>.ast, :type(CSSValue::URLComponent));
    }

    # uri - synonym for url?
    method uri($/)   { make $<url>.ast }

    method any-dimension($/) {
        return $.warning("unknown units: { $<units:unknown>.ast }")
            unless $.lax;
        make $.build.node( $/ )
    }

    method color-range($/) {
        my $range = $<num>.ast.value;
        $range *= 2.55
            if $<percentage>;

        # clip out-of-range colors, see
        # http://www.w3.org/TR/CSS21/syndata.html#value-def-color
        $range = min( max($range, 0), 255);
        make $.build.token( $range.round, :type(CSSValue::NumberComponent));
    }

    method alpha-value($/) {
        my $alpha = $<num>.ast.value;
        $alpha /= 100
            if $<percentage>;
        $alpha = min( max($alpha, 0), 1);
        make $.build.token( $alpha.round(.01), :type(CSSValue::NumberComponent));
    }

    proto method color {*}
    method color:sym<rgb>($/)  {
        return $.warning('usage: rgb(c,c,c) where c is 0..255 or 0%-100%')
            if $<any-args>;

        make $.build.token( $.build.list($/), :type<rgb>);
    }

    method color:sym<hex>($/)   {
        my $id = $<id>.ast.value;
        my $chars = $id.chars;
        return $.warning("bad hex color", ~$/)
            unless $chars == 3|6 && $id ~~ /^<xdigit>+$/;
        my @rgb = $chars == 3
            ?? $id.comb.map: {$^hex-digit ~ $^hex-digit}
            !! $id.comb.map: {$^hex-digit ~ $^hex-digit2};

        my $num-type = CSSValue::NumberComponent.Str;
        my @color = @rgb.map: { $num-type => :16($_) };

        make $.build.token( @color, :type<rgb>);
    }

    method prio($/) {
        return $.warning("dropping term", ~$/)
            if $<any> || !$0;

        make $0.lc
    }

    # from the TOP (CSS1 + CSS21 + CSS3)
    method TOP($/) { make $<stylesheet>.ast }
    method stylesheet($/) { make $.build.token( $.build.list($/), :type(CSSObject::StyleSheet)) }

    method charset($/)   { make $.build.at-rule($/) }
    method import($/)    { make $.build.at-rule($/) }
    method url-string($/){ make $.build.token($<string>.ast, :type(CSSValue::URLComponent)) }

    method misplaced($/) {
        $.warning('ignoring out of sequence directive', ~$/)
    }

    method operator($/) { make $.build.token( ~$/, :type(CSSValue::OperatorComponent)) }

    # pseudos
    method pseudo:sym<:element>($/)  { make $.build.token( $<element>.lc, :type(CSSSelector::PseudoElement)) }
    method pseudo:sym<::element>($/) { make $.build.token( $<element>.lc, :type(CSSSelector::PseudoElement)) }
    method pseudo:sym<function>($/)  { make $<pseudo-function>.ast }
    method pseudo:sym<class>($/)     { make $.build.token( $<class>.ast, :type(CSSSelector::PseudoClass)) }

    # combinators
    method combinator:sym<adjacent>($/) { make '+' }
    method combinator:sym<child>($/)    { make '>' }
    method combinator:sym<not>($/)      { make '-' } # css21

    method !code-point(Str $hex-str --> Int) {
        return :16( ~$hex-str );
    }

    method unicode-range($/) {
        my Str ($lo, $hi);

        with $<mask> {
            my $mask = .Str;
            $lo = $mask.subst('?', '0'):g;
            $hi = $mask.subst('?', 'F'):g;
        }
        else {
            $lo = ~$<from>;
            $hi = ~$<to>;
        }

        make $.build.token( [ self!code-point( $lo ), self!code-point( $hi ) ], :type(CSSValue::UnicodeRangeComponent));
    }

    # css21/css3 core - media support
    method at-rule:sym<media>($/) { make $.build.at-rule($/) }
    method rule-list($/)          { make $.build.token( $.build.list($/), :type(CSSObject::RuleList)) }
    method media-list($/)         { make $.build.list($/) }
    method media-query($/)        { make $.build.list($/) }
    method media-name($/)         { make $.build.token( $<Ident>.ast, :type(CSSValue::IdentifierComponent)) }

    # css21/css3 core - page support
    method at-rule:sym<page>($/)  { make $.build.at-rule($/) }
    method page-pseudo($/)        { make $.build.token( $<Ident>.ast, :type(CSSSelector::PseudoClass)) }

    method property($/)           { make $<Ident>.ast }
    method ruleset($/)            { make $.build.token( $.build.node($/), :type(CSSObject::RuleSet)) }
    method selectors($/)          { make $.build.token( $.build.list($/), :type(CSSSelector::SelectorList)) }
    method declarations($/)       { make $.build.token( $<declaration-list>.ast, :type(CSSValue::PropertyList) ) }
    method declaration-list($/)   { make [$<declaration>>>.ast.grep: {.defined}] }
    method declaration($/)        { make $<any-declaration>.ast }
    method at-keyw($/)            { make $<Ident>.ast }
    method any-declaration($/)    {
        return if $<dropped-decl>;

        return make $.build.at-rule($/)
            if $<declarations>;

        return $.warning('dropping declaration', $<Ident>.ast)
            if !$<expr>.caps
            || $<expr>.caps.first({! .value.ast.defined});

        make $.build.token($.build.node($/), :type(CSSValue::Property));
    }

    method term($/) { make $<term>.ast }

    method expr($/) { make $.build.token( $.build.list($/), :type(CSSValue::ExpressionComponent)) }
    method term1:sym<percentage>($/) { make $<percentage>.ast }

    method term2:sym<dimension>($/)  { make $<dimension>.ast }
    method term2:sym<function>($/)   { make $.build.token( $<function>.ast, :type(CSSValue::FunctionComponent)) }

    proto method length {*}
    method length:sym<dim>($/) { make $.build.token($<num>.ast, :type($<units>.ast)); }
    method dimension:sym<length>($/) { make $<length>.ast }
    method length:sym<rel-font-length>($/) { make $<rel-font-length>.ast }
    method rel-font-length($/) {
        my $num = $<sign> && ~$<sign> eq '-' ?? -1 !! +1;
        make $.build.token($num, :type( $<rel-font-units>.lc ));
    }

    proto method angle {*}
    method angle-units($/)         { make $/.lc }
    method angle:sym<dim>($/)      { make $.build.token( $<num>.ast, :type($<units>.ast)) }
    method dimension:sym<angle>($/){ make $<angle>.ast }

    proto method time {*}
    method time-units($/)          { make $/.lc }
    method time:sym<dim>($/)       { make $.build.token( $<num>.ast, :type($<units>.ast)) }
    method dimension($/)           { make $<dimension>.ast }
    method dimension:sym<time>($/) { make $<time>.ast }

    proto method frequency {*}
    method frequency-units($/)     { make $/.lc }
    method frequency:sym<dim>($/)  { make $.build.token( $<num>.ast, :type($<units>.ast)) }
    method dimension:sym<frequency>($/) { make $<frequency>.ast }

    method resolution:sym<dim>($/)        { make $.build.token($<num>.ast, :type($0.lc) ) }
    method dimension:sym<resolution>($/)  { make $<resolution>.ast }

    method percentage($/)          { make $.build.token( $<num>.ast, :type(CSSValue::PercentageComponent)) }

    method term1:sym<string>($/)   { make $.build.token( $<string>.ast, :type(CSSValue::StringComponent)) }
    method term1:sym<url>($/)      { make $.build.token( $<url>.ast, :type(CSSValue::URLComponent)) }
    method term1:sym<color>($/)    { make $<color>.ast }

    method term1:sym<num>($/)      { make $.build.token( $<num>.ast, :type(CSSValue::NumberComponent)); }
    method term1:sym<ident>($/)    { make $<Ident>
                                         ?? $.build.token( $<Ident>.ast, :type(CSSValue::IdentifierComponent)) 
                                         !! $<rel-font-length>.ast
                                   }

    method term1:sym<unicode-range>($/) { make $.build.token($<unicode-range>.ast, :type(CSSValue::UnicodeRangeComponent)) }

    method selector($/)            { make $.build.token( $.build.list($/), :type(CSSSelector::Selector)) }

    method universal($/)           { make $.build.token( {element-name => ~$/}, :type(CSSValue::QnameComponent)) }
    method qname($/)               { make $.build.token( $.build.node($/), :type(CSSValue::QnameComponent)) }
    method simple-selector($/)     { make $.build.token( $.build.list($/), :type(CSSSelector::SelectorComponent)) }

    method attrib($/)              { make $.build.list($/) }

    method any-function($/) {
        return $.warning('skipping function arguments', ~$_)
            with $<any-args>;
        make $.build.node($/);
    }

    method pseudo-function:sym<lang>($/) {
        return $.warning('usage: lang(ident)')
            with $<any-args>;
        make $.build.pseudo-func( 'lang' , $/);
    }

    method any-pseudo-func($/) {
        make $.build.token( .ast, :type(CSSSelector::PseudoFunction) )
            with $<any-function>;
    }

    # css 2.1 attribute selectors
    method attribute-selector:sym<equals>($/)     { make ~$/ }
    method attribute-selector:sym<includes>($/)   { make ~$/ }
    method attribute-selector:sym<first-word>($/) { make ~$/ }
    # css 3 attribute selectors
    method attribute-selector:sym<prefix>($/)     { make ~$/ }
    method attribute-selector:sym<suffix>($/)     { make ~$/ }
    method attribute-selector:sym<substring>($/)  { make ~$/ }
    method attribute-selector:sym<column>($/)     { make ~$/ }

    # An+B microsyntax
    method op-sign($/) { make ~$/ }
    method op-n($/)    { make 'n' }

    method AnB-expr:sym<keyw>($/) { make [ $.build.token( $<keyw>.ast, :type(CSSValue::KeywordComponent)) ] }
    method AnB-expr:sym<expr>($/) { make $.build.list($/) }

    method end-block($/) {
        $.warning("no closing '}'")
            unless $<closing-paren>;
    }

    method unclosed-comment($/) {
        $.warning('unclosed comment at end of input');
    }

    method unknown($/) {
        $.warning('dropping', ~$/)
    }
}
