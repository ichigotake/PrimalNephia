# NAME

Nephia - Mini WAF

# SYNOPSIS

    ### Get started the Nephia!
    $ nephia-setup MyApp
    

    ### And, plackup it!
    $ cd myapp
    $ plackup

# DESCRIPTION

Nephia is a mini web-application framework.

# MOUNT A CONTROLLER

Use "path" function as following in lib/MyApp.pm . 

First argument is path for mount a controller. This must be string.

Second argument is controller-logic. This must be code-reference.

In controller-logic, you may get Plack::Request object as first-argument, 
and controller-logic must return response-value as hash-reference or Plack::Response object.

## Basic controller - Makes JSON response

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

## Use templates - Render with Text::MicroTemplate

    path '/' => sub {
        return {
            template => 'index.html',
            title => 'Welcome to my homepage!',
        };
    };

Attention to "template" attribute. 
If you specified it, controller searches template file from view-directory and render it.

If you use multibyte-string in response, please remember `use utf8` and, you may specify character-set as like as following.

    use utf8; ### <- very important
    path '/' => sub {
        return {
            template => 'mytemplate.tx',
            title => 'わたしのホォムペェジへよおこそ！',
            charset => 'Shift_JIS',
        };
    };

If you not specified `charset`, it will be 'UTF-8'.

## Makes response - Using "res" function

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
        return res { 404 } unless req->param('q');
        return { ( 200, [], ['you say '. req->param('q')] ) };
    };

Commands supported in "res" function are following.

- status 
- headers 
- header
- body 
- content\_type
- content\_length
- content\_encoding
- redirect
- cookies

Please see Plack::Response's documentation for more detail.

## Limitation by request method - Using (get|post|put|del) function

    ### catch request that contains get-method
    get '/foo' => sub { ... };
    

    ### post-method is following too.
    post '/bar' => sub { ... };
    

    ### put-method and delete-method are too.
    put '/baz' => sub { ... };
    del '/hoge' => sub { ... };

## How to use routing with Router::Simple style matching-pattern and capture it - Using param function

    post '/item/{id:[0-9]+}' => sub {
        my $item_id = param->{id}; # get param named "id" from path
        ...
    };

# USING CONFIG

First, see app.psgi that generated by `nephia-setup`.

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

# STATIC CONTENTS ( like as image, javascript ... )

You can look static-files that is into root directory via HTTP.

# USING PLUGINS

You may use plugins for Nephia, as like followings.

    use Nephia plugins => [qw[Response::YAML Response::XML]];

or

    BEGIN {
        use Nephia;
        nephia_plugin 'Response::YAML', 'Response::XML';
    }

# HOW TO DEVELOP Nephia PLUGIN

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

# FUNCTIONS

## path $path, $coderef\_as\_controller;

Mount controller on specified path.

## get post put del

Usage equal as path(). But these functions specifies limitation for HTTP request-method.

## req

Return Plack::Request object. You can call this function in code-reference that is argument of path().

## res $coderef

Return Plack::Response object with some DSL.

## param

Return parameters that contains in path as hashref. 

## config

Return config as hashref.

## nephia\_plugins @plugins

Load specified Nephia plugins.

# AUTHOR

`ytnobody` <ytnobody@gmail.com>

`ichigotake`

`papix`

and Nephia contributors, hachioji.pm

# SEE ALSO

Plack::Request

Plack::Response

Plack::Builder

Text::MicroTemplate

JSON

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
