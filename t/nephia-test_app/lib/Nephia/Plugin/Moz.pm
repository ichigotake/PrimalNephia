package Nephia::Plugin::Moz;
use strict;
use warnings;
use utf8;

our $WORD;

sub load {
    my ($class, $app, $opt) = @_;
    $WORD = $opt->{word};
}

sub process_env {
    my $env = shift;
    $env->{QUERY_STRING} = "foo=bar";
    return $env;
}

sub process_response {
    my $res = shift;
    $res->header('X-Moz' => $WORD);
    return $res;
}

sub process_content {
    my $content = shift;
    $content =~ s/o/i/g;
    return $content;
}

1;
