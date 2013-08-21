package PrimalNephia::ParentApp::ChildApp;
use strict;
use warnings;
use utf8;

use PrimalNephia;

path '/' => sub {
    res {
        body ('this location in child_app.')
    };
};



1;

