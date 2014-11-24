use v6;

use CSS::AST::Info;
use CSS::AST::Token;

class CSS::AST does CSS::AST::Info {

    # These tables map AST types to standard W3C component definitions.

    # CSS object definitions based on http://dev.w3.org/csswg/cssom/
    # for example 6.4.1 CSSRuleList maps to CSSObject::RuleList
    our Str enum CSSObject is export(:CSSObject) «
        :CharsetRule<charset-rule>
        :FontFaceRule<fontface-rule>
        :GroupingRule<grouping-rule>
        :ImportRule<import>
        :MarginRule<margin-rule>
        :MediaRule<media-rule>
        :NamespaceRule<namespace-rule>
        :PageRule<page-rule>
        :Priority<prio>
        :RuleSet<ruleset>
        :RuleList<rule-list>
        :StyleDeclaration<style>
        :StyleRule<style-rule>
        :StyleSheet<stylesheet>
        »;

    # CSS value types based on http://dev.w3.org/csswg/cssom-values/
    # for example 3.3 CSSStyleDeclarationValue maps to CSSValue::StyleDeclaration
    our Str enum CSSValue is export(:CSSValue) «
        :ColorComponent<color>
        :Component<value>
        :IdentifierComponent<ident>
        :KeywordComponent<keyw>
        :LengthComponent<length>
        :Map<map>
        :PercentageComponent<percent>
        :Property<property>
        :PropertyList<declarations>
        :StringComponent<string>
        :URLComponent<url>

        :NameComponent<name>
        :NumberComponent<num>
        :IntegerComponent<int>
        :AngleComponent<angle>
        :FrequencyComponent<freq>
        :FunctionComponent<func>
        :ResolutionComponent<resolution>
        :TimeComponent<time>
        :QnameComponent<qname>
        :NamespacePrefixComponent<ns-prefix>
        :ElementNameComponent<element-name>
        :OperatorComponent<op>
        :ExpressionComponent<expr>
        :ArgumentListComponent<args>
        :AtKeywordComponent<@>
        :UnicodeRangeComponent<unicode-range>
    »;

    # an enumerated list of all unit types for validation purposes.
    # Adapted from the out-of-date http://www.w3.org/TR/DOM-Level-2-Style/css.html

    our Str enum CSSUnits is export(:CSSUnits) «
        :ems<length> :exs<length> :px<length> :cm<length> :mm<length> :in<length> :pt<length> :pc<length>
        :em<length> :ex<length> :rem<length> :ch<length> :vw<length> :vh<length> :vmin<length> :vmax<length>
        :dpi<resolution> :dpcm<resolution> :dppx<resolution>
        :deg<angle> :rad<angle> :grad<angle> :turn<angle>
        :ms<time> :s<time>
        :hz<freq> :khz<freq>
        :rgb<color> :rgba<color> :hsl<color> :hsla<color>
    »;

    our Str enum CSSSelector is export(:CSSSelector) «
        :AttributeSelector<attrib>
        :AttributeOp<attribute-selector>
        :Class<class>
        :Combinator<combinator>
        :Id<id>
        :MediaList<media-list>
        :MediaQuery<media-query>
        :PseudoClass<pseudo-class>
        :PseudoElement<pseudo-elem>
        :PseudoFunction<pseudo-func>
        :SelectorList<selectors>
        :Selector<selector>
        :SelectorComponent<simple-selector>
    »;

    # from http://dev.w3.org/csswg/cssom-view/
    our Str enum CSSTrait is export(:CSSTrait) «:Box<box>»;

BEGIN our %known-type =
    %( CSSObject.enums.invert ),
    %( CSSValue.enums.invert ),
    %( CSSSelector.enums.invert ),
    ;

    method token(Mu $ast, :$type is copy, :$trait) {

        die 'usage: $.token($ast, :$type || :$trait)'
            unless $type || $trait;

        return unless $ast.defined;

        my $units;

        if $type.defined && (my $inferred-type = CSSUnits.enums{$type}) {
            $units = $type;
            $type = $inferred-type
        }

        if $type.defined {
            my $raw-type = $type.subst(/':'.*/,'');
            die "unknown type: '$raw-type'"
                unless %known-type{$raw-type}:exists;
        }

        $ast
            does CSS::AST::Token
            unless $ast.can('type');

        $ast.type = $type.Str   if $type.defined;
        $ast.units = $units.Str if $units.defined;
        $ast.trait = $trait.Str if $trait.defined;

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
                $key = $key.lc;
                my ($type, $_class) = $key.split(':');

                $value = $value.ast
                    // $capture && $capture eq $key && ~$value;
                next if $key eq '0' || !$value.defined;

                if substr($key, 0, 5) eq 'expr-' {
                    $key = $key.subst(/^'expr-'/, 'expr:')
                }
                elsif $value.can('type') {
                    $key = $value.units // $value.type;
                }
                elsif %known-type{$type}:exists {
                    $value = $.token( $value, :type($key) );
                }
                else {
                    warn "{$value.perl} has unknown type: $key";
                }

                if %terms{$key}:exists {
                    $.warning("repeated term " ~ $key, $value);
                    return Any;
                }

                %terms{$key} = $value;
            }
        }

        return %terms;
    }

    method list($/, :$capture? ) {
        # make a node that contains repeatable elements
        my @terms;

        # unwrap Parcels
        my @l = $/.can('caps')
            ?? ($/)
            !! $/.grep({ .defined });

        for @l {
            for .caps -> $cap {
                my ($key, $value) = $cap.kv;

                $key = $key.lc;
                my ($type, $_class) = $key.split(':');

                $value = $value.ast
                    // $capture && $capture eq $key && ~$value;
                next if $key eq '0' || !$value.defined;

                if substr($key, 0, 5) eq 'expr-' {
                    $key = $key.subst(/^'expr-'/, 'expr:')
                }
                elsif $value.can('type') {
                    $key = $value.units // $value.type;
                }
                elsif %known-type{$type}:exists {
                    $value = $.token( $value, :type($key));
                }
                else {
                    warn "{$value.perl} has unknown type: $key";
                }

                push( @terms, {$key => $value} );
            }
        }

        return @terms;
    }

}
