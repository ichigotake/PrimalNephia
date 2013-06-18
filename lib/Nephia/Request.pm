package Nephia::Request;
use strict;
use warnings;

use parent 'Plack::Request';
use Encode;
use Hash::MultiValue;

sub uri {
    my $self = shift;

    $self->{uri} ||= $self->SUPER::uri;
    $self->{uri}->clone; # avoid destructive opearation
}

sub base {
    my $self = shift;

    $self->{base} ||= $self->SUPER::base;
    $self->{base}->clone; # avoid destructive operation
}

sub body_parameters {
    my ($self) = @_;
    $self->{body_parameters} ||= $self->_decode_parameters($self->SUPER::body_parameters);
}

sub query_parameters {
    my ($self) = @_;
    $self->{query_parameters} ||= $self->_decode_parameters($self->SUPER::query_parameters);
}

sub _decode_parameters {
    my ($self, $stuff) = @_;

    my @flatten = $stuff->flatten;
    my @decoded;
    while ( my ($k, $v) = splice @flatten, 0, 2 ) {
        push @decoded, Encode::decode_utf8($k), Encode::decode_utf8($v);
    }
    return Hash::MultiValue->new(@decoded);
}
sub parameters {
    my $self = shift;
    $self->{'request.merged'} ||= do {
        my $query = $self->query_parameters;
        my $body  = $self->body_parameters;
        Hash::MultiValue->new( $query->flatten, $body->flatten );
    };
}

sub body_parameters_raw {
    shift->SUPER::body_parameters;
}
sub query_parameters_raw {
    shift->SUPER::query_parameters;
}

sub parameters_raw {
    my $self = shift;
    $self->env->{'plack.request.merged'} ||= do {
        my $query = $self->SUPER::query_parameters;
        my $body  = $self->SUPER::body_parameters;
        Hash::MultiValue->new( $query->flatten, $body->flatten );
    };
}

sub param_raw {
    my $self = shift;

    return keys %{ $self->parameters_raw } if @_ == 0;

    my $key = shift;
    return $self->parameters_raw->{$key} unless wantarray;
    return $self->parameters_raw->get_all($key);
}

1;
