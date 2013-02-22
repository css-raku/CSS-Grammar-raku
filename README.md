perl6-CSS-Grammar
=================

Perl 6 CSS related grammars (under construction)

CSS::Grammar is a set of grammars for the W3C CSS family of standards.

It aims to implement a reasonable portion of the standards; in particular:

- rules for forward compatibility, scanning and error recovery
- CSS3 / CSS4 modules and the ability to pick and choose grammar subsets
- Mechanisms for custom CSS extensions

This distribution includes:

- `CSS::Grammar::CSS1`  - CSS 1.0 compatable grammar
- `CSS::Grammar::CSS21` - CSS 2.1 compatable grammar
- `CSS::Grammar::CSS3`  - CSS 3.0 (core) compatable grammar
- `CSS::Grammar::Actions`  - Actions for CSS1, CSS2 and CSS3 (core)
- `CSS::Grammar::CSS3::Module::Fonts` - CSS 3.0 Fonts extension module
- `CSS::Grammar::CSS3::Module::Colors` - CSS 3.0 Colors extension module

Bundling CSS Modules
--------------------
CSS3 is evolving an extensive set of modules. Each is optional
and may extend both the grammar and generated Abstract Syntax Tree (AST). This
leads to a large number of possible grammar combinations.

This distribtion takes the approach of making it easy to compose a custom grammar thats includes the modules that you intend to support.

In general, to support module XXXX you need to build a custom grammar on the fly
that inherits `CSS::Grammar::CSS3::Module::XXXX`; Likewise, you'll need to build a custom action class that inherits `CSS::Grammar::CSS3::Module::XXXX::Actions`.

E.g. if you want to support the core CSS3 grammar plus the colors and fonts modules:

    use CSS::Grammar::CSS3;
    use CSS::Grammar::Actions;
    use CSS::Grammar::CSS3::Module::Colors;
    use CSS::Grammar::CSS3::Module::Fonts;

    grammar MyApp::CSS3::Grammar
          is CSS::Grammar::CSS3
          is CSS::Grammar::CSS3::Module::Colors
          is CSS::Grammar::CSS3::Module::Fonts {};

    class MyApp::CSS3::Actions
        is CSS::Grammar::Actions
        is CSS::Grammar::CSS3::Module::Colors::Actions
        is CSS::Grammar::CSS3::Module::Fonts::Actions {};

For working examples, see t/parse-css3-module-colors.t, t/parse-css3-module-fonts.t.

CSS3 also allows for vendor extensions. You should be able to add your
own custom grammar extensions and bundle them using the above mechanisms.
