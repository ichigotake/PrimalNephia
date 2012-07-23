package Nephia;
@ISA = qw( Exporter );
use strict;
use warnings;

use Exporter 'import';
use Plack::Request;
use Plack::Response;
use Plack::Builder;
use Plack::App::URLMap;
use Text::Xslate;
use JSON ();

our $VERSION = '0.01';
our @EXPORT = qw( path res run composit );
our $MAPPER = Plack::App::URLMap->new;
our $VIEW;

sub path ($&) {
    my ( $path, $code ) = @_;

    $MAPPER->map( $path => sub {
        my $env = shift;
        my $req = Plack::Request->new( $env );
        my $res = $code->( $req );
        if ( ref $res eq 'HASH' ) {
            return $res->{template} ? 
                render( $res ) : 
                json_res( $res )
            ;
        }
        elsif ( ref $res eq 'Plack::Response' ) {
            return $res->finalize;
        }
        else {
            return $res;
        }
    } );
}

sub res (&) {
    my $code = shift;
    my $res = Plack::Response->new(200);
    $res->content_type('text/html');
    {
        no strict qw( refs subs );
        no warnings qw( redefine );
        my $caller = caller();
        map { 
            my $method = $_;
            *{$caller.'::'.$method} = sub { 
                return $res->$method( @_ );
            };
        } qw( 
            status headers body header
            content_type content_length
            content_encoding redirect cookies
        );
        $code->();
    }
    return $res;
}

sub run {
    $VIEW = Text::Xslate->new(
        path => [ './view' ]
    );
    return builder { $MAPPER->to_app };
}

sub json_res {
    my $res = shift;
    my $body = JSON->new->utf8->encode( $res );
    return [ 200, 
        [ 'Content-type' => 'application/json', 
          'Content-length' => length $body 
        ],
        [ $body ]
    ];
}

sub render {
    my $res = shift;
    my $body = $VIEW->render( $res->{template}, $res );
    return [ 200,
        [ 'Content-type' => 'text/html; charset=UTF-8',
          'Content-length' => length $body
        ],
        [ $body ]
    ];
}

1;
__END__

=head1 NAME

Nephia - Mini WAF

=head1 SYNOPSIS

  ### Get started the Nephia!
  $ nephia-setup MyApp
  
  ### And, plackup it!
  $ cd myapp
  $ plackup

=head1 DESCRIPTION

Nephia is a mini web-application framework.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
