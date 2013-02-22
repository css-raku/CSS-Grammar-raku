perl6-CSS-Grammar
=================

Perl 6 CSS related grammars (under construction)

CSS::Grammar is a set of grammars for the W3C CSS family of standards.

It aims to implement a reasonable portion of the standards; in particular:

- rules for forward compatibility, scanning and error recovery
- CSS3 / CSS4 modules and the ability to define grammar subsets
- Mechanisms for custom CSS extensions

This distribution currently includes:

- `CSS::Grammar::CSS1`  - CSS 1.0 compatible grammar
- `CSS::Grammar::CSS21` - CSS 2.1 compatible grammar
- `CSS::Grammar::CSS3`  - CSS 3.0 (core) compatible grammar
- `CSS::Grammar::Actions`  - Actions for CSS1, CSS2 and CSS3 (core)
- `CSS::Grammar::CSS3::Module::Fonts` - CSS 3.0 Fonts extension module
- `CSS::Grammar::CSS3::Module::Colors` - CSS 3.0 Colors extension module

Defining CSS3 Subsets
---------------------
CSS3 is evolving into an extensive set of [modules](http://www.css3.info/modules/).
Most are optional and may extend both the grammar and generated Abstract Syntax
Tree (AST). This leads to a large number of possible ways of combining grammars.

The CSS3 core is quite miminalistic; For example, it does not understand colors.

You will probably need to define your own custom grammar subset and
set of parsing actions that are tailored to the particular CSS3 modules that
you intend to support.

E.g. to support the following definitions support the CSS3 Core grammar
plus the Colors and Fonts modules:

    use CSS::Grammar::CSS3;
    use CSS::Grammar::CSS3::Module::Colors;
    use CSS::Grammar::CSS3::Module::Fonts;
    use CSS::Grammar::Actions;

    grammar My_Custom_CSS3_Grammar
          is CSS::Grammar::CSS3
          is CSS::Grammar::CSS3::Module::Colors
          is CSS::Grammar::CSS3::Module::Fonts {};

    class My_Custom_CSS3_Actions
        is CSS::Grammar::Actions
        is CSS::Grammar::CSS3::Module::Colors::Actions
        is CSS::Grammar::CSS3::Module::Fonts::Actions {};

This gives you a customised grammar and parser that understands just the
core CSS3 language, plus Colors and Fonts. Other CSS elements will be
ignored.

    my $actions = My_Custom_CSS3_Actions.new;
    my $parse = My_Custom_CSS3_Grammar.parse( $css_input, :actions($actions) );

For working examples, see t/parse-css3-module-colors.t, t/parse-css3-module-fonts.t.

