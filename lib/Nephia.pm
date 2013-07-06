package Nephia;
use strict;
use warnings;
use File::Spec;
our $VERSION = '0.25';

sub import {
    my ($class, %opts) = @_;
    my @plugins = ! $opts{plugins} ? () :
                  ref($opts{plugins}) eq 'ARRAY' ? @{$opts{plugins}} :
                  ( $opts{plugins} )
    ;

    no strict 'refs';

    my $caller = caller;
    use Nephia::Core;

    for my $func (grep { $_ =~ /^[a-z]/ && $_ ne 'import' } keys %{'Nephia::Core::'}) {
        *{$caller.'::'.$func} = *{'Nephia::Core::'.$func};
    }

    for my $plugin ( map {"Nephia::Plugin::$_"} @plugins ) {
        require File::Spec->catfile(split/::/, $plugin.'.pm');
        {
            no warnings 'once'; ### suppress warning for fetching import coderef
            $plugin->import if *{$plugin."::import"}{CODE};
        }
        for my $func (grep { $_ =~ /^[a-z]/ && $_ ne 'import' } keys %{$plugin.'::'}) {
            *{$caller.'::'.$func} = *{$plugin.'::'.$func};
        }
    }
}

1;
__END__

=encoding utf8

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
          query => param('q'),
      };
  };

This controller outputs response-value as JSON, and will be mounted on "/foobar".

=head2 Use templates - Render with Text::MicroTemplate

  path '/' => sub {
      return {
          template => 'index.html',
          title => 'Welcome to my homepage!',
      };
  };

Attention to "template" attribute.
If you specified it, controller searches template file from view-directory and render it.

If you use multibyte-string in response, please remember C<use utf8> and, you may specify character-set as like as following.

  use utf8; ### <- very important
  path '/' => sub {
      return {
          template => 'mytemplate.tx',
          title => 'わたしのホォムペェジへよおこそ！',
          charset => 'Shift_JIS',
      };
  };

If you not specified C<charset>, it will be 'UTF-8'.

=head2 Makes response - Using "res" function

  path '/my-javascript' => sub {
      return res {
          content_type( 'text/javascript' );
          body( 'alert("Oreore!");' );
      };
  };

"res" function returns Plack::Response object with some DSL.

You may specify code-reference that's passed to res() returns some value. These values are passed into arrayref that is as plack response.

  path '/some/path' => sub {
      res { ( 200, ['text/html; charset=utf8'], ['Wooootheee!!!'] ) };
  };

And, you can write like following.

  path '/cond/sample' => sub {
      return res { 404 } unless param('q');
      return res { ( 200, [], ['you say '. param('q')] ) };
  };

Commands supported in "res" function are following.

=over 4

=item status

=item headers

=item header

=item body

=item content_type

=item content_length

=item content_encoding

=item redirect

=item cookies

=back

Please see Plack::Response's documentation for more detail.

=head2 Limitation by request method - Using (get|post|put|del) function

  ### catch request that contains get-method
  get '/foo' => sub { ... };

  ### post-method is following too.
  post '/bar' => sub { ... };

  ### put-method and delete-method are too.
  put '/baz' => sub { ... };
  del '/hoge' => sub { ... };

=head2 How to use routing with Router::Simple style matching-pattern and capture it - Using param function WITHOUT args

  post '/item/{id:[0-9]+}' => sub {
      my $item_id = param->{id}; # get param named "id" from path
      ...
  };

=head2 Submapping to other applications that use Nephia

It's easy. Call "path" function by package instead of a coderef.

  path '/otherapp' => 'OtherApp';

in OtherApp:

  package OtherApp;
  use Nephia;

  get '/message' => sub {
      message => 'this is other app!'
  };

This controller mapped to "/otherapp/message".

Can use "+" prefix in package name. This prefix replace to package of myself.

Example:

  package MyApp;

  path '/childapp' => '+Child';

"/chilapp" connect to "MyApp::Child".

=head2 Using Cookie

If you want to set cookie, use "set_cookie" command.

  path '/somepath' => sub {
      set_cookie cookiename => 'cookievalue';
      return +{ ... };
  };

And, getting a cookie value, use "cookie" command.

  path '/anypath' => sub {
      my $cookie_value = cookie 'cookiename';
      return +{ ... };
  };

=head1 USING CONFIG

First, see app.psgi that generated by C<nephia-setup>.

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

=head1 STATIC CONTENTS ( like as image, javascript ... )

You can look static-files that is into root directory via HTTP.

=head1 USING PLUGINS

You may use plugins for Nephia, as like followings.

  use Nephia plugins => [qw[Response::YAML Response::XML]];

or

  BEGIN {
      use Nephia;
      nephia_plugin 'Response::YAML', 'Response::XML';
  }

=head1 HOW TO DEVELOP Nephia PLUGIN

The only rule, namespace of new module must begins in "Nephia::Plugin::".

If you want to export subroutines, those name must begin in lower alphabetic chars, and it must not be "import".

import() will execute when plugin is loaded.

For example.

  package Nephia::Plugin::Bark;
  use strict;
  use warnings;

  sub import {
      my ($class) = @_;
      ... ### Be execute when plugin is loaded.
  }

  sub bark () {
      return [200, [], ['Bark!']];
  }

  sub barkbark (@) {
      return [200, [], [join(' ', 'Bark', @_)]];
  }

  1;

You can use plugin in above, as like followings.

  package Your::App;
  use Nephia plugins => ['Bark'];

  path '/bark' => sub {
      bark; # 'Bark!'
  };

  path '/barkbark' => sub {
      barkbark 'hoge', 'fuga'; # 'Bark hoge fuga'
  };

=head1 FUNCTIONS

=head2 path $path, $coderef_as_controller;

Mount controller on specified path.

=head2 get post put del

Usage equal as path(). But these functions specifies limitation for HTTP request-method.

=head2 req

Return Plack::Request object. You can call this function in code-reference that is argument of path().

=head2 res $coderef

Return Plack::Response object with some DSL.

=head2 param

Return parameters that contains in path as hashref.

=head2 param $param_name

Return specified query-parameter. (As like as "req->param($param_name)")

=head2 config

Return config as hashref.

=head2 base_dir

Return the absolute path to root of application.

=head2 cookie $cookie_name

Get specified cookie value.

=head2 set_cookie $cookie_name => $cookie_value

Set value into specified cookie.

=head2 nephia_plugins @plugins

Load specified Nephia plugins.

=head1 AUTHOR

C<ytnobody> E<lt>ytnobody@gmail.comE<gt>

C<ichigotake>

C<papix>

and Nephia contributors, hachioji.pm

=head1 SEE ALSO

Plack::Request

Plack::Response

Plack::Builder

Text::MicroTemplate

JSON

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
