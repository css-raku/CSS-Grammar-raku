use v6;

# css3 - with all extensions enabled
use CSS::Grammar::CSS3;
use CSS::Grammar::CSS3::Module::Colors;
use CSS::Grammar::CSS3::Module::Fonts;
use CSS::Grammar::CSS3::Module::Media;
use CSS::Grammar::CSS3::Module::Namespaces;
use CSS::Grammar::CSS3::Module::PagedMedia;
use CSS::Grammar::CSS3::Module::Selectors;

use CSS::Grammar::Actions;

grammar CSS::Grammar::CSS3::Extended
    is CSS::Grammar::CSS3::Module::Colors
    is CSS::Grammar::CSS3::Module::Fonts
    is CSS::Grammar::CSS3::Module::Media
    is CSS::Grammar::CSS3::Module::Namespaces
    is CSS::Grammar::CSS3::Module::PagedMedia
    is CSS::Grammar::CSS3::Module::Selectors
    is CSS::Grammar::CSS3
{};

class  CSS::Grammar::CSS3::Extended::Actions
    is CSS::Grammar::CSS3::Module::Colors::Actions
    is CSS::Grammar::CSS3::Module::Fonts::Actions
    is CSS::Grammar::CSS3::Module::Media::Actions
    is CSS::Grammar::CSS3::Module::Namespaces::Actions
    is CSS::Grammar::CSS3::Module::PagedMedia::Actions
    is CSS::Grammar::CSS3::Module::Selectors::Actions
    is CSS::Grammar::Actions
{};
