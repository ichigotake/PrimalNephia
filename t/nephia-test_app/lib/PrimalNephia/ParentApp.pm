package PrimalNephia::ParentApp;
use strict;
use warnings;
use utf8;

use PrimalNephia;

path '/' => sub {
    res {
        body ('this location in parent_app.')
    };
};

path '/subapp' => '+PrimalNephia::SubApp';
path '/childapp' => 'ChildApp';
path '/subapp2' => '+PrimalNephia::SubApp';

1;

