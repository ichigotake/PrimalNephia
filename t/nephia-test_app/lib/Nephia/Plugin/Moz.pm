package Nephia::Plugin::Moz;
use strict;
use warnings;
use utf8;
use JSON;
use Nephia::Request;
use Encode;

our $WORD;
our @EXPORT = qw/appname/;

sub load {
    my ($class, $app, $opt) = @_;
    $WORD = $opt->{word};
}

sub appname {
    return context('app');
}

sub before_action {
    my ($env, $path_param, @action_chain) = @_;
    my $req = Nephia::Request->new($env);
    if (my $moz = $req->param('moz')) {
        if ($moz eq 'shock-sheets') {
            return [
                200, 
                ['Content-Type' => 'text/plain; charset=UTF-8'], 
                [Encode::encode_utf8('職質なう')]
            ];
        }
    }
    my $next = shift(@action_chain);
    $next->($env, $path_param, @action_chain);
}

sub process_env {
    my $env = shift;
    $env->{QUERY_STRING} = "foo=bar";
    context(moznion => '職');
    return $env;
}

sub process_response {
    my $res = shift;
    $res->header('X-Moz' => $WORD);
    my $moz = context('moznion');
    context(moznion => $moz.'質');
    return $res;
}

sub process_content {
    my $content = shift;
    my $json = JSON->new->utf8;
    my $moz = context('moznion');
    my $data = $json->decode($content);
    $data->{message} =~ s/o/i/g;
    $data->{message} .= $moz;
    return $json->encode($data);
}

1;
