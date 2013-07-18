package Nephia::TestPluginApp2nd;
use strict;
use warnings;
use utf8;
use Nephia plugins => ['Moz' => {word => 'kieeeee'}];

path '/' => sub {
    return {
        message => '八王子なう',
        params  => param('foo'),
        appname => appname,
    };
};

1;
