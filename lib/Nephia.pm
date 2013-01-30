package Nephia;
use strict;
use warnings;

use Exporter 'import';
use Plack::Request;
use Plack::Response;
use Plack::Builder;
use Router::Simple;
use Nephia::View;
use JSON ();
use FindBin;
use Data::Validator;
use Encode;

our $VERSION = '0.03';
our @EXPORT = qw[ get post put del path req res param run validate config app ];
our $MAPPER = Router::Simple->new;
our $VIEW;
our $CONFIG = {};
our $CHARSET = 'UTF-8';

sub _path {
    my ( $path, $code, $methods ) = @_;
    my $caller = caller();
    $MAPPER->connect(
        $path, 
        {
            action => sub {
                my $req = Plack::Request->new( shift );
                my $param = shift;
                no strict qw[ refs subs ];
                no warnings qw[ redefine ];
                local *{$caller."::req"} = sub{ $req };
                local *{$caller."::param"} = sub{ $param };
                my $res = $code->( $req, $param );
                if ( ref $res eq 'HASH' ) {
                    return eval { $res->{template} } ? 
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
            },
        },
        $methods ? { method => $methods } : undef,
    );
}

sub get ($&) {
    my ( $path, $code ) = @_;
    _path( $path, $code, ['GET'] );
}

sub post ($&) {
    my ( $path, $code ) = @_;
    _path( $path, $code, ['POST'] );
}

sub put ($&) {
    my ( $path, $code ) = @_;
    _path( $path, $code, ['PUT'] );
}

sub del ($&) {
    my ( $path, $code ) = @_;
    _path( $path, $code, ['DELETE'] );
}

sub path ($@) {
    my ( $path, $code, $methods ) = @_;
    _path( $path, $code, $methods );
}

sub res (&) {
    my $code = shift;
    my $res = Plack::Response->new(200);
    $res->content_type('text/html');
    {
        no strict qw[ refs subs ];
        no warnings qw[ redefine ];
        my $caller = caller();
        map { 
            my $method = $_;
            *{$caller.'::'.$method} = sub (@) { 
                return $res->$method( @_ );
            };
        } qw[ 
            status headers body header
            content_type content_length
            content_encoding redirect cookies
        ];
        $code->();
    }
    return $res;
}

sub run {
    my ( $class, %options ) = @_;
    $CONFIG = { %options };
    $VIEW = Nephia::View->new( %{$options{view}} );
    return builder { 
        enable "ContentLength";
        enable "Static", root => "$FindBin::Bin/root/", path => qr{^/static/};
        $class->app;
    };
}

sub app {
    my $class = shift;
    return sub {
        my $env = shift;
        if ( my $p = $MAPPER->match($env) ) {
            $p->{action}->($env, $p);
        }
        else {
            [404, [], ['Not Found']];
        }
    };
}

sub json_res {
    my $res = shift;
    my $body = JSON->new->utf8->encode( $res );
    return [ 200, 
        [ 'Content-type' => 'application/json' ],
        [ $body ]
    ];
}

sub render {
    my $res = shift;
    my $charset = delete $res->{charset} || $CHARSET;
    my $body = $VIEW->render( $res->{template}, $res );
    return [ 200,
        [ 'Content-type' => "text/html; charset=$charset" ],
        [ Encode::encode( $charset, $body ) ]
    ];
}

sub validate (%) {
    my $caller = caller();
    no strict qw[ refs subs ];
    no warnings qw[ redefine ];
    my $req = *{$caller.'::req'};
    my $validator = Data::Validator->new(@_);
    return $validator->validate( %{$req->()->parameters->as_hashref_mixed} );
}

sub config (@) {
    if ( scalar @_ > 0 ) {
        $CONFIG = 
            scalar @_ > 1 ? { @_ } : 
            ref $_[0] eq 'HASH' ? $_[0] :
            do( $_[0] )
        ;
    }
    return $CONFIG;
};

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

=head1 MOUNT A CONTROLLER

Use "path" function as following in lib/MyApp.pm . 

First argument is path for mount a controller. This must be string.

Second argument is controller-logic. This must be code-reference.

In controller-logic, you may get Plack::Request object as first-argument, 
and controller-logic must return response-value as hash-reference or Plack::Response object.

=head2 Basic controller - Makes JSON response

Look this examples.

  path '/foobar' => sub {
      my ( $req ) = @_;
      # Yet another syntax is following.
      # my $req = req;
  
      return {
          name => 'MyApp',
          query => $req->param('q'),
      };
  };

This controller outputs response-value as JSON, and will be mounted on "/foobar".

=head2 Use templates - Render with Xslate (Kolon-syntax)

  path '/' => sub {
      return {
          template => 'index.tx',
          title => 'Welcome to my homepage!',
      };
  };

Attention to "template" attribute. 
If you specified it, controller searches template file from view-directory and render it.

If you use multibyte-string in response, please remember 'use utf8;' and, you may specify character-set as like as following.

  path '/' => sub {
      return {
          template => 'mytemplate.tx',
          title => 'わたしのホォムペェジへよおこそ！',
          charset => 'Shift_JIS',
      };
  };

If you not specified 'charset', it will be 'UTF-8'.

=head2 Makes response - Using "res" function

  path '/my-javascript' => sub {
      return res {
          content_type( 'text/javascript' );
          body( 'alert("Oreore!");' );
      };
  };

"res" function returns Plack::Response object with customisable DSL-like syntax.

=head2 Limitation by request method - Using (get|post|put|del) function

  ### catch request that contains get-method
  get '/foo' => sub { ... };
  
  ### post-method is following too.
  post '/bar' => sub { ... };
  
  ### put-method and delete-method are too.
  put '/baz' => sub { ... };
  del '/hoge' => sub { ... };

=head2 How to use routing with Router::Simple style matching-pattern and capture it - Using param function

  post '/item/{id:[0-9]+}' => sub {
      my $item_id = param->{id}; # get param named "id" from path
      ...
  };

=head1 USING CONFIG

First, see app.psgi that generated by nephia-setup.

  use strict;
  use warnings;
  use FindBin;
  
  use lib ("$FindBin::Bin/lib", "$FindBin::Bin/extlib/lib/perl5");
  use MyApp;
  MyApp->run;

You may define config with run method as like as following.

  MyApp->run( 
    attr1   => 'value',
    logpath => '/path/to/log',
    ...
  );

And, you can access to these config in your application as following.

  path '/foo/bar' => sub {
    my $config = config;
  };

=head1 STATIC CONTENTS ( like as images, javascripts... )

You can look static-files that is into root directory via HTTP.

=head1 VALIDATE PARAMETERS

You may use validator with validate function.

  path '/some/path' => sub {
      my $params = validate
          name => { isa => 'Str', default => 'Nameless John' },
          age => { isa => 'Int' }
      ;
  };

See documentation of validate method and Data::Validator.

=head1 FUNCTIONS

=head2 path $path, $coderef_as_controller;

Mount controller on specified path.

=head2 get post put del

Usage equal as path(). But these functions specifies limitation for HTTP request-method.

=head2 req

Return Plack::Request object. You can call this function in coderef that is argument of path().

=head2 res $coderef

Return Plack::Response object with customisable DSL-like syntax.

=head2 param

Return parameters that contains in path as hashref. 

=head2 config

Return config as hashref.

=head2 validate %validation_rules

Return validated parameters as hashref. You have to set validation rule as like as Data::Validator's instantiate arguments.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=head1 SEE ALSO

Plack::Request

Plack::Response

Plack::Builder

Text::Xslate

Text::Xslate::Syntax::Kolon

JSON

Data::Validator

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
