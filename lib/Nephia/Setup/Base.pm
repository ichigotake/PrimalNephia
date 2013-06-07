package Nephia::Setup::Base;
use strict;
use warnings;
use File::Spec;
use Path::Class;
use Cwd;
use Carp;
use Class::Accessor::Lite (
    new => 0,
    rw => [qw( appname approot pmpath templates )],
);

sub new {
    my ( $class, %opts ) = @_;

    my $appname = $opts{appname}; $appname =~ s/::/-/g;
    $opts{approot} = dir( File::Spec->catfile( '.', $appname ) );

    $opts{pmpath} = file( File::Spec->catfile( $opts{approot}->stringify, 'lib', split(/::/, $opts{appname}. '.pm') ) );
    my @template_data = ();
    {
        no strict 'refs';
        my $dh = *{'Nephia::Setup::Base::DATA'}{IO};
        push @template_data, (<$dh>);
        if ($class ne 'Nephia::Setup::Default' ) {
            my $_dh = *{$class.'::DATA'}{IO};
            push @template_data, (<$_dh>);
        }
    }
    $opts{templates} = _parse_template_data( @template_data );

    return bless { %opts }, $class;
}

sub _parse_template_data {
    my @data = @_;
    return +{
        map { 
            my ($key, $template) = split("---", $_, 2); 
            $key =~ s/(\s|\r|\n)//g;
            $template =~ s/^\n//;
            ($key, $template);
        } 
        grep { $_ =~ /---/ }
        split("===", join('', @data) )
    };
}

sub create {
    my $self = shift;

    $self->approot->mkpath( 1, 0755 );
    map {
        $self->approot->subdir($_)->mkpath( 1, 0755 );
    } qw( lib etc etc/conf view root root/static t );

    $self->psgi_file;
    $self->app_class_file;
    $self->index_template_file;
    $self->css_file;
    $self->makefile;
    $self->basic_test_file;
    $self->config_file;
}

sub nephia_version {
    my $self = shift;
    return $self->{nephia_version} ? $self->{nephia_version} : do {
        require Nephia;
        $Nephia::VERSION;
    };
}

sub psgi_file {
    my $self = shift;
    my $appname = $self->appname;
    my $body = $self->templates->{psgi_file};
    $body =~ s[\$appname][$appname]g;
    $self->approot->file('app.psgi')->spew( $body );
}

sub app_class_file {
    my $self = shift;
    my $approot = $self->approot;
    my $appname = $self->appname;
    my $body = $self->templates->{app_class_file};
    $body =~ s[\$approot][$approot]g;
    $body =~ s[\$appname][$appname]g;
    $body =~ s[:::][=]g;
    $self->pmpath->dir->mkpath( 1, 0755 );
    $self->pmpath->spew( $body );
}

sub index_template_file {
    my $self = shift;
    my $body = $self->templates->{index_template_file};
    $self->approot->file('view', 'index.tx')->spew( $body );
}

sub css_file {
    my $self = shift;
    my $body = $self->templates->{css_file};
    $self->approot->file('root', 'static', 'style.css')->spew( $body );
}

sub makefile {
    my $self = shift;
    my $appname = $self->appname;
    $appname =~ s[::][-]g;
    my $pmpath = $self->pmpath;
    $pmpath =~ s[$appname][.];
    my $version = $self->nephia_version;
    my $body = $self->templates->{makefile};
    $body =~ s[\$appname][$appname]g;
    $body =~ s[\$pmpath][$pmpath]g;
    $body =~ s[\$NEPHIA_VERSION][$version]g;
    $self->approot->file('Makefile.PL')->spew( $body );
}

sub basic_test_file {
    my $self = shift;
    my $appname = $self->appname;
    my $body = $self->templates->{basic_test_file};
    $body =~ s[\$appname][$appname]g;
    $self->approot->file('t','001_basic.t')->spew( $body );
}

sub config_file {
    my $self = shift;
    my $appname = $self->appname;
    $appname =~ s[::][-]g;
    my $common = $self->templates->{common_conf};
    $common =~ s[\$appname][$appname]g;
    my $common_conf = $self->approot->file('etc','conf','common.pl');
    my $common_conf_path = $common_conf->stringify;
    $common_conf_path =~ s[^$appname][.];
    $common_conf->spew( $common );
    for my $envname (qw( development staging production )) {
        my $body = $self->templates->{conf_file};
        $body =~ s[\$common_conf_path][$common_conf_path]g;
        $body =~ s[\$envname][$envname]g;
        $self->approot->file('etc','conf',$envname.'.pl')->spew( $body );
    }
}

1;

__DATA__

psgi_file
---
use strict;
use warnings;
use FindBin;
use Config::Micro;
use File::Spec;

use lib ("$FindBin::Bin/lib", "$FindBin::Bin/extlib/lib/perl5");
use $appname;
my $config = require( Config::Micro->file( dir => File::Spec->catdir('etc','conf') ) );
$appname->run( $config );
===

app_class_file
---
package $appname;
use strict;
use warnings;
use Nephia;

our $VERSION = 0.01;

path '/' => sub {
    my $req = shift;
    return {
        template => 'index.tx',
        title    => config->{appname},
        envname  => config->{envname},
        apppath  => 'lib/' . __PACKAGE__ .'.pm',
    };
};

path '/data' => sub {
    my $req = shift;
    return { # return JSON unless {template}
        #template => 'index.tx',
        title    => config->{appname},
        envname  => config->{envname},
    };
};

1;

:::head1 NAME

$appname - Web Application

:::head1 SYNOPSIS

  $ plackup

:::head1 DESCRIPTION

$appname is web application based Nephia.

:::head1 AUTHOR

clever guy

:::head1 SEE ALSO

Nephia

:::head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

:::cut

===

index_template_file
---
<html>
<head>
  <link rel="stylesheet" href="/static/style.css" />
  <link rel="shortcut icon" href="/static/favicon.ico" />
  <title><: $title :> - powerd by Nephia</title>
</head>
<body>
  <div class="title">
    <span class="title-label"><: $title :></span>
    <span class="envname"><: $envname :></span>
  </div>

  <div class="content">
    <h2>Hello, Nephia world!</h2>
    <p>Nephia is a mini web-application framework.</p>
    <pre>
    ### <: $apppath :>
    use Nephia;

    # <a href="/data">JSON responce sample</a>
    path '/data' => sub {
        my $req = shift;

        return { # responce-value as JSON unless exists {template}
            #template => 'index.tx',
            title    => config->{appname},
            envname  => config->{envname},
        };
    };
    </pre>
    <h2>See also</h2>
    <ul>
      <li><a href="https://metacpan.org/module/Nephia">Read the documentation</a></li>
    </ul>
  </div>

  <address class="generated-by">Generated by Nephia</address>
</body>
</html>

===

css_file
---
body {
    background: #f7f7f7;
    color: #666;
    padding: 0px;
    margin: 0px;
    font-family: 'Hiragino Kaku Gothic ProN', Meiryo, 'MS PGothic', Sans-serif;
}

h1,h2,h3,h4,h5 {
    color: #333;
    border-left: 10px solid #36c;
    font-weight: 100;
    padding: 4px 7px;
}

a {
    color: #36c;
}

div.title {
    width: 100%;
    margin: 0px;
    padding: 0px;
    background-color: #36c;
    border-bottom: 2px solid #fff;
    color: #f7f7f7;
}

span.title-label {
    font-weight: 100;
    font-size: 1.4em;
    margin: 0px 10px;
}

span.envname {
    font-size: 0.8em;
}

div.content {
    background-color: #fff;
    width: 80%;
    margin: 20px auto;
    padding: 10px 30px;
    border-radius: 4px;
    border: 2px solid #eee;
}

pre {
    line-height: 1.2em;
    padding: 10px 2px;
    background-color: #f5f5f5;
    border-radius: 4px;
    border: 1px solid #eee;
    text-shadow:none;
    color: #111;
}

address.generated-by {
    width: 80%;
    padding: 0px 30px;
    margin: auto;
    margin-top: 20px;
    text-align: right;
    font-style: normal;
}

===

makefile
---
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => '$appname',
    AUTHOR           => q{clever guy <who@example.com>},
    VERSION_FROM     => '$pmpath',
    ABSTRACT_FROM    => '$pmpath',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Nephia' => '$NEPHIA_VERSION',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => '$appname-*' },
);


===

basic_test_file
---
use strict;
use warnings;
use Test::More;
BEGIN {
    use_ok( '$appname' );
}
done_testing;
===

common_conf
---
### common config
+{
    appname => '$appname',
};
===

conf_file
---
### environment specific config
use File::Spec;
use File::Basename 'dirname';
my $basedir = File::Spec->rel2abs(
    File::Spec->catdir( dirname(__FILE__), '..', '..' )
);
+{
    %{ do(File::Spec->catfile($basedir, 'etc', 'conf', 'common.pl')) },
    envname => '$envname',
};
===
