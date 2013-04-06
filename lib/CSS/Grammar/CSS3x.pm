use v6;

# css3 - with all extensions enabled
grammar CSS::Grammar::CSS3x {...};
class   CSS::Grammar::CSS3x::Actions {...};

use CSS::Grammar::CSS3;
use CSS::Grammar::CSS3x::Colors;
use CSS::Grammar::CSS3x::Fonts;
use CSS::Grammar::CSS3x::Media;
use CSS::Grammar::CSS3x::Namespaces;
use CSS::Grammar::CSS3x::PagedMedia;
use CSS::Grammar::CSS3x::Selectors;

use CSS::Grammar::Actions;

grammar CSS::Grammar::CSS3x
    is CSS::Grammar::CSS3x::Colors
    is CSS::Grammar::CSS3x::Fonts
    is CSS::Grammar::CSS3x::Media
    is CSS::Grammar::CSS3x::Namespaces
    is CSS::Grammar::CSS3x::PagedMedia
    is CSS::Grammar::CSS3x::Selectors
    is CSS::Grammar::CSS3
{};

class CSS::Grammar::CSS3x::Actions
    is CSS::Grammar::CSS3x::Colors::Actions
    is CSS::Grammar::CSS3x::Fonts::Actions
    is CSS::Grammar::CSS3x::Media::Actions
    is CSS::Grammar::CSS3x::Namespaces::Actions
    is CSS::Grammar::CSS3x::PagedMedia::Actions
    is CSS::Grammar::CSS3x::Selectors::Actions
    is CSS::Grammar::Actions
{};
