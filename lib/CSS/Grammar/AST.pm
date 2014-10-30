use v6;

# AST: CSS Parse Abstract Syntax Tree Objects - tba

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

        :NumberComponent<num>  # e.g. z-index
        :AngleComponent<angle>
        :FrequencyComponent<frequency>
        :FunctionComponent<function>
        :TimeComponent<time>

    »;

    # from http://dev.w3.org/csswg/cssom-view/
    our Str enum CSSTrait is export(:CSSTrait) «:Box<box>»;

}


