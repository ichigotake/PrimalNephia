package PrimalNephia::Plugin;
use strict;
use warnings;

1;
__END__

=encoding utf8

=head1 NAME 

PrimalNephia::Plugin - Documentation for Plugins

=head1 USING PLUGINS

You may use plugins as followings.

  use PrimalNephia plugins => ['Response::YAML', 'Auth::Twitter' => { consumer_key => ..., }];

or

  BEGIN {
      use PrimalNephia;
      nephia_plugin 'Response::YAML', 'Response::XML';
  }

=head1 HOW TO DEVELOP PrimalNephia PLUGIN

Basic rule is namespace of new module must begins in "PrimalNephia::Plugin::".

If you want to export subroutines, those name must begin in lower alphabetic chars, and it must not be "import" and "load".

import() and load() will execute when plugin is loaded.

And, you can use context() function for set/get some state among request.

For example.

  package PrimalNephia::Plugin::Bark;
  use strict;
  use warnings;
  use PrimalNephia::Request;
  
  our @EXPORT = qw/bark barkbark/;

  sub import {
      my ($class) = @_;
      ... ### Execute when plugin is loaded.
  }

  sub load {
      my ($class, $app_class, $plugin_config) = @_;
      ### Execute after import()
      ...
  }

  sub before_action {
      my ($env, $path_param, @action_chain) = @_;
      context(sound => plugin_config('sound'));  # set sound into context
      my $req = context('req');
      if (my $id = $req->param('id')) {
          return [403, [], ['You denied!'] ] if $id eq 'ytnobody';  # deny ytnobody :(
      }
      my $next = shift(@chain_of_actions);
      $next->($env, $path_param, @chain_of_actions);
  }

  sub process_env {
      my $env = shift;
      $env->{HTTP_X_OREORE} = 'oreore'; # inject into http request header
      return $env;
  }

  sub process_response {
      my $res = shift;
      $res->header('X-Oreore' => 'soregashi soregashi'); # inject into http response header
      return $res;
  }

  sub process_content {
      my $content = shift;
      # <b>...</b> to <span class="bold">...</span>
      $content =~ s|<b>|<span class="bold">|g;
      $content =~ s|</b>|</span>|g;
      return $content;
  }

  sub bark () {
      my $sound = context('sound');   # get sound from context
      return [200, [], [$sound]];
  }

  sub barkbark (@) {
      my $sound = context('sound');   # get sound from context
      return [200, [], [join(' ', $sound, @_)]];
  }

  1;

You can use plugin in above, as like followings.

  package Your::App;
  use PrimalNephia plugins => [Bark => {sound => 'Bark!'}];

  path '/bark' => sub {
      bark; # 'Bark!'
  };

  path '/barkbark' => sub {
      barkbark 'hoge', 'fuga'; # 'Bark hoge fuga'
  };

=head1 Hooks for development plugins

=over 4

=item $psgi_res = before_action( $env, $path_param, @chain_of_actions )

Rewrite action when request incoming.

=item $new_env = process_env( $origin_env );

Rewrite Plack env when build request.

=item $res = process_response( $raw_res );

Rewrite response object after response was built.

=item $content = process_content( $raw_content );

Rewrite content before responde response.

=back

=head1 Helper DSL for development plugins

=over 4

=item $specified_conf_value = plugin_config($keyname);

Returns specified value of plugin config 

=item $stored_value = context($keyname);

Returns specified value that stored in context

=item context($keyname => $value);

Store $value into context that is labeled specified keyname

=back

=cut

