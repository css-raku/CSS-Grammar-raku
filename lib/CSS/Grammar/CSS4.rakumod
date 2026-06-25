unit grammar CSS::Grammar::CSS4;

use CSS::Grammar::CSS3;
also is CSS::Grammar::CSS3;

rule color:sym<rgb>  {:i 'rgb('
			 [ <color-range> **3% ','? [ <[,/]>? <alpha-value> ]? || <any-args> ]
                     ')'}
