package Nephia::GlobalVars;

use strict;
use warnings;
use utf8;

our $AUTOLOAD;
our $STORED_DATA ||= {};

sub AUTOLOAD {
    my ($class, $var) = @_;
    my ($method) = $AUTOLOAD =~ /^$class\:\:([0-9a-z_]+)$/;
    if ($method) {
        $STORED_DATA->{$method} = $var if defined $var;
        return $STORED_DATA->{$method};
    }
}

sub import {}

sub store {
    my ($class, %data) = @_;
    $STORED_DATA = {%data};
}

1;
