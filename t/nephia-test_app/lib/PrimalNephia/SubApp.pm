package PrimalNephia::SubApp;
use strict;
use warnings;
use utf8;

use PrimalNephia;

path '/' => sub {
    res {
        body ('this location in sub_app.')
    };
};


1;

