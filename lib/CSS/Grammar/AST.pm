use v6;

use CSS::Grammar::AST::Info;
use CSS::Grammar::AST::Token;

class CSS::Grammar::AST does CSS::Grammar::AST::Info {

    # These tables map AST types to standard W3C component definitions.

    # CSS object definitions based on http://dev.w3.org/csswg/cssom/
    # for example 6.4.1 CSSRuleList maps to CSSObject::RuleList
    our Str enum CSSObject is export(:CSSObject) «
        :CharsetRule<charset-rule>
        :FontFaceRule<fontface-rule>
        :GroupingRule<grouping-rule>
        :ImportRule<import-rule>
        :MarginRule<margin-rule>
        :MediaRule<media-rule>
        :NamespaceRule<namespace-rule>
        :PageRule<page-rule>
        :Rule<rule>
        :RuleList<rule-list>
        :StyleDeclaration<style>
        :StyleRule<style-rule>
        :StyleSheet<style-sheet>
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

        # Extension components. These do not have corresponding definitions in csssom-values

        :NumberComponent<num>
        :IntegerComponent<int>  # e.g. z-index
        :AngleComponent<angle>
        :FrequencyComponent<freq>
        :FunctionComponent<func>
        :ResolutionComponent<resolution>
        :TimeComponent<time>
        :QnameComponent<qname>
        :OperatorComponent<op>
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
        :PseudoFunction<pseudo-func>
    »;

    # from http://dev.w3.org/csswg/cssom-view/
    our Str enum CSSTrait is export(:CSSTrait) «:Box<box>»;

our %known-type = BEGIN
    %( CSSObject.enums.invert ),
    %( CSSValue.enums.invert ),
    %( CSSSelector.enums.invert ),
    ;

    method token(Mu $ast, :$type is copy, :$units is copy, :$trait) {

        return unless $ast.defined;

        my $inferred-type;

        if $units.defined {
            $inferred-type = CSSUnits.enums{$units}
            or die "unknown units: $units";

        }
        elsif $type.defined && ($inferred-type = CSSUnits.enums{$type}) {
            $units = $type;
            $type = $inferred-type
        }

        if $inferred-type {
            die "type conflict for units $units; inferred: $inferred-type, actual: $type"
                if $type.defined && $type ne $inferred-type;

            $type //= $inferred-type;
        }

        die 'usage: $.token( ... :$type || :$unit || :$trait)'
            unless $type || $trait;

        die "unknown type: $type"
            if $type.defined && (%known-type{$type}:!exists);

        $ast
            does CSS::Grammar::AST::Token
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

                $value = $value.ast
                    // $capture && $capture eq $key && ~$value;

                if $value.can('type') {
                    $key = $value.units // $value.type;
                }

                if %terms{$key}:exists {
                    $.warning("repeated term " ~ $key, $value);
                    return Any;
                }

                %terms{$key.subst(/^'expr-'/, '').lc} = $value
                if $value.defined;
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

                $value = $value.ast
                    // $capture && $capture eq $key && ~$value;

                if $value.can('type') {
                    $key = $value.units // $value.type;
                }

                push( @terms, {$key.subst(/^'expr-'/, '').lc => $value} )
                    if $value.defined;
            }
        }

    return @terms;
}

}
