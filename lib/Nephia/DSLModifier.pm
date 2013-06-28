package Nephia::DSLModifier;
use strict;
use warnings;
use parent 'Exporter';
use Carp;

our @EXPORT = qw/before around after origin/;

sub origin ($) {
    my ($method_name) = @_;
    no strict 'refs';
    *{'Nephia::Core::'.$method_name}{CODE};
}

sub around ($&) {
    my ($method_name, $coderef) = @_;
    no strict 'refs';
    no warnings 'redefine';
    my $orig = Nephia::DSLModifier::origin($method_name) or die "specified unsupported DSL '$method_name'";
    *{'Nephia::Core::'.$method_name} = sub { $coderef->(@_, $orig) };
}

sub before ($&) {
    my ($method_name, $coderef) = @_;
    Nephia::DSLModifier::around($method_name, sub {
        my $orig = pop; 
        $coderef->(@_);
        $orig->(@_);
    });
}

sub after ($&) {
    my ($method_name, $coderef) = @_;
    Nephia::DSLModifier::around($method_name, sub {
        my $orig = pop; 
        $orig->(@_);
        $coderef->(@_);
    });
}

1;
