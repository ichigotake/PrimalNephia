package Nephia::Context;
use strict;
use warnings;
use utf8;

our $AUTOLOAD;

sub AUTOLOAD {
    my ($self, $var) = @_;
    my $class = __PACKAGE__;
    my ($method) = $AUTOLOAD =~ /^$class\:\:([0-9a-z_]+)$/;
    if ($method) {
        $self->{$method} = $var if defined $var;
        return $self->{$method};
    }
}

sub import {}

sub new {
    my ($class, %opts) = @_;
    bless {%opts}, $class;
}

1;
