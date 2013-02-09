use v6;

role CSS::Grammar::AST::Info {
    has Str $.type where /^(at_rule|string|ruleset|stylesheet|url)$/;
    # $.skip - W3C compliant processors should skip processing of this
    #          node and its children
    has Bool $.skip is rw;

    has $.css_type is rw;

    # $.line_no - source line number
    has Int $.line_no is rw;
}
