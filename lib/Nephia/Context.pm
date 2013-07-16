package Nephia::Context;
use strict;
use warnings;
use utf8;

sub new {
    my ($class, %opts) = @_;
    bless {%opts}, $class;
}

1;
