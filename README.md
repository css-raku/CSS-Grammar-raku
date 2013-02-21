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
- `CSS::Grammar::CSS3::Module::Font` - CSS 3.0 Fonts extension module

Bundling CSS Modules
--------------------
CSS3 is evolving an extensive set of optional modules. Each are optional
and extend both the grammar and generated Abstract Syntax Tree (AST).

We've just got a stub for the Fonts module at the moment; but here's how it'll
will work:

You need to compose a custom grammar thats include `CSS::Grammar::CSS3::Module::XXXX` and a custom action class that includes `CSS::Grammar::CSS3::Module::XXXX::Actions`.

E.g. to build a custom CSS3 subset that includes the core CSS3 grammar
plus the fonts module:

    use CSS::Grammar::CSS3;
    use CSS::Grammar::Actions;
    use CSS::Grammar::CSS3::Module::Fonts;

    grammar MyApp::CSS3::FontGrammar
          is CSS::Grammar::CSS3
          is CSS::Grammar::CSS3::Module::Fonts {};

    class MyApp::CSS3::FontActions
        is CSS::Grammar::Actions
        is CSS::Grammar::CSS3::Module::Fonts::Actions {};

For an example, seee t/parse-css3-module-fonts.t

CSS3 also allows for vendor extensions. You should be able to easily add your
own custom grammar extensions and bundle them using the above mechanisms.
