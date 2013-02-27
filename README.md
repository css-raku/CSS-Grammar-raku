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

Including CSS3 Extensions
-------------------------
CSS3 is evolving into a core grammar plus an extensive set of extension
[modules](http://www.css3.info/modules/). Most are optional and may extend
both the grammar and generated Abstract Syntax Tree (AST). This leads to a
large number of possible grammar dialects.

You may need to define custom grammar and action classes for
the particular CSS3 modules that you intend to support.

E.g. to support the CSS3 Core grammar plus the Fonts modules:

    use CSS::Grammar::CSS3;
    use CSS::Grammar::CSS3::Module::Fonts;
    use CSS::Grammar::Actions;

    grammar My_Custom_CSS3_Grammar
          is CSS::Grammar::CSS3::Module::Fonts
          is CSS::Grammar::CSS3 {};

    class My_Custom_CSS3_Actions
        is CSS::Grammar::CSS3::Module::Fonts::Actions
        is CSS::Grammar::Actions {};

This gives you a customised grammar and parser that understands the
core CSS3 language, plus Fonts. Any references, to other CSS extensions
will be ignored.

    my $actions = My_Custom_CSS3_Actions.new;
    my $parse = My_Custom_CSS3_Grammar.parse( $css_input, :actions($actions) );

For a working example, see t/parse-css3-module-fonts.t.


