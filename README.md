perl6-CSS-Grammar
=================

Perl 6 CSS related grammars (under construction)

CSS::Grammar is a set of grammars for the W3C CSS family of standards.

It aims to implement a reasonable portion of the standards; in particular:

- rules for forward compatibility, scanning and error recovery
- CSS3 / CSS4 modules and the ability to define grammar subsets
- Mechanisms for custom CSS extensions

Installation (Rakudo Star)
--------------------------
You'll first need to download and build Rakudo Star 2012.11 or better (http://rakudo.org/downloads/star/ - don't forget the final `make install`):

Ensure that `perl6` and `panda` are available on your path, e.g. :

    % export PATH=~/src/rakudo-star-2012.11/install/bin:$PATH

You can then use `panda` to test and install `CSS::Grammar`:


    % panda install CSS::Grammar

To try parsing some content:

    % perl6 -MCSS::Grammar::CSS3 -e"say CSS::Grammar::CSS3.parse('H1 {color:blue}')"


Contents
========

Base Grammars
-------------
- `CSS::Grammar::CSS1`  - CSS 1.0 compatible grammar
- `CSS::Grammar::CSS21` - CSS 2.1 compatible grammar
- `CSS::Grammar::CSS3`  - CSS 3.0 (core) compatible grammar
- `CSS::Grammar::CSS3::Extended` - CSS3 plus all available extensions
- `CSS::Grammar::Actions` - Parser actions for CSS1, CSS2 and CSS3 base grammars

CSS3 Extension Modules
----------------------
- `CSS::Grammar::CSS3::Module::Colors` - CSS 3.0 Colors
- `CSS::Grammar::CSS3::Module::Selectors` - CSS 3.0 Selectors
- `CSS::Grammar::CSS3::Module::Fonts` - CSS 3.0 Fonts (@font-face)
- `CSS::Grammar::CSS3::Module::Media` - CSS 3.0 Media (@media)
- `CSS::Grammar::CSS3::Module::Namespaces` - CSS 3.0 Namespace (@namespace)
- `CSS::Grammar::CSS3::Module::PagedMedia` - CSS 3.0 Paged Media (@page)

CSS3 Core Grammar
-----------------
The CSS 3 core grammar, `CSS::Grammar::CSS3`, is mostly feature-compatabile with CSS2.1. In particular, it understands:

- `#hex` and `rgb(...)` colors; but not `rgba(..)`, `hsl(...)`, or `hsla(...)`.
- basic `@media` at-rules; but not advanced media queries, resolutions or embedded `@page` rules.
- basic `@page` page description rules
- basic css2.1 compatibile selectors.

CSS3 Extended Grammar
---------------------
Grammar `CSS::Grammar::CSS3::Extended` and class
CSS::Grammar::CSS3::Extended::Actions` are included for your convenience. They
have all currently implemented extensions enabled.

    use CSS::Grammar::CSS3::Extended;

Enabling Specific CSS3 Extensions
---------------------------------
CSS3 is evolving into a core grammar plus a comprehensive set of extension
[modules](http://www.css3.info/modules/). Most are optional and may extend
both the grammar and generated Abstract Syntax Tree (AST). This leads to a
large number of possible grammar combinations.

If you wish to use a subset of the available extensions, you'll need to
construct a custom grammar and actions that include just the particular CSS3
extension modules that you intend to support.

E.g. to support the CSS3 Core grammar plus Paged Media and Fonts modules:

    use CSS::Grammar::CSS3;
    use CSS::Grammar::CSS3::Module::Fonts;
    use CSS::Grammar::CSS3::Module::PagedMedia;
    use CSS::Grammar::Actions;

    grammar My_CSS3_Grammar
        is CSS::Grammar::CSS3::Module::Fonts
        is CSS::Grammar::CSS3::Module::PagedMedia
        is CSS::Grammar::CSS3 {};

    class My_CSS3_Actions
        is CSS::Grammar::CSS3::Module::Fonts::Actions
        is CSS::Grammar::CSS3::Module::PagedMedia::Actions
        is CSS::Grammar::Actions {};

This gives you a customised grammar and parser that understands the
core CSS3 language, plus Fonts and Paged Media extensions

    my $actions = My_CSS3_Actions.new;
    my $parse = My_CSS3_Grammar.parse( $css_input, :actions($actions) );

For a working example, see t/parse-css3-module-fonts.t.

References
==========
These grammars have been built from the W3C CSS Specifications. In particular:

- CSS 1.0 Grammar - http://www.w3.org/TR/2008/REC-CSS1-20080411/#appendix-b
- CSS 2.1 Grammar - http://www.w3.org/TR/CSS21/grammar.html
- CSS3 module: Syntax - http://www.w3.org/TR/2003/WD-css3-syntax-20030813/
- CSS Selectors Module Level 3 - http://www.w3.org/TR/2011/REC-css3-selectors-20110929/
- CSS Color Module Level 3 - http://www.w3.org/TR/2011/REC-css3-color-20110607/
- CSS Fonts Module Level 3 - http://www.w3.org/TR/2013/WD-css3-fonts-20130212/
- CSS Namespaces Module - http://www.w3.org/TR/2011/REC-css3-namespace-20110929/
- CSS3 Media Query Extensions - http://www.w3.org/TR/2012/REC-css3-mediaqueries-20120619/
- CSS3 Module: Paged Media - http://www.w3.org/TR/2006/WD-css3-page-20061010/
