use v6;

# CSS3 Namespaces Extension Module
# specification: http://www.w3.org/TR/2011/REC-css3-namespace-20110929/
#

grammar CSS::Grammar::CSS3::Module::Namespaces:ver<20110929.000> {
    rule at_decl:sym<namespace> {(:i'namespace') <prefix=.ident>? [<url=.string>|<url>] ';' }
}

class CSS::Grammar::CSS3::Module::Namespaces::Actions {
    method at_decl:sym<namespace>($/) { make $.at_rule($/) }
}

