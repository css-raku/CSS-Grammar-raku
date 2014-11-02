use v6;

use CSS::Grammar::AST::Info;

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
        :StyleDeclaration<style-decl>
        :StyleRule<style-rule>
        :StyleSheet<style-sheet>
        »;

    # CSS value types based on http://dev.w3.org/csswg/cssom-values/
    # for example 3.3 CSSStyleDeclarationValue maps to CSSValue::StyleDeclaration
    our Str enum CSSValue is export(:CSSValue) «
        :ColorComponent<color>
        :Component<value>
        :IdentifierComponent<ident>
        :KeywordComponent<keyword>
        :LengthComponent<length>
        :Map<map>
        :PercentageComponent<percent>
        :Property<property>
        :PropertyList<property-list>
        :StringComponent<string>
        :StyleDeclaration<style>
        :URLComponent<url>

        # These components can occur in the AST, but do not have corresponding definitions in csssom-values

        :NumberComponent<num>
        :IntegerComponent<int>  # e.g. z-index
        :AngleComponent<angle>
        :FrequencyComponent<frequency>
        :FunctionComponent<function>
        :ResolutionComponent<resolution>
        :TimeComponent<time>
    »;

    # an enumerated list of all unit types for validation purposes.
    # Adapted from the out-of-date http://www.w3.org/TR/DOM-Level-2-Style/css.html

    our Str enum CSSUnits is export(:CSSUnits) «
        :ems<length> :exs<length> :px<length> :cm<length> :mm<length> :in<length> :pt<length> :pc<length>
        :em<length> :ex<length> :rem<length> :ch<length> :vw<length> :vh<length> :vmin<length> :vmax<length>
        :dpi<resolution> :dpcm<resolution> :dppx<resolution>
        :deg<angle> :rad<angle> :grad<angle> :turn<angle>
        :ms<time> :s<time>
        :hz<frequency> :khz<frequency>
        :rgb<color> :rgba<color> :hsl<color> :hsla<color>
    »;

    # from http://dev.w3.org/csswg/cssom-view/
    our Str enum CSSTrait is export(:CSSTrait) «:Box<box>»;

}
