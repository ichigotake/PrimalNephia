package Nephia::PluginLoader;
use strict;
use warnings;
use Module::Load ();

sub load {
    my $caller = caller();
    my @plugins = @_;

    while (@plugins) {
        my $plugin = shift @plugins;
        $plugin = _normalize_plugin_name($plugin);

        my $opt = $plugins[0] && ref $plugins[0] ? shift @plugins : undef;
        _export_plugin_functions($plugin, $caller, $opt);
    }

};

sub _normalize_plugin_name {
    local $_ = shift;
    /^\+/ ? s/^\+// && $_ : "Nephia::Plugin::$_";
}

sub _export_plugin_functions {
    my ($plugin, $pkg, $opt) = @_;

    Module::Load::load($plugin);
    {
        no strict qw/refs subs/;
        no warnings qw/redefine prototype/;
        *{$plugin.'::context'} = sub { 
            my ($key, $val) = @_;
            $Nephia::Core::CONTEXT->{$key} = $val if defined $key && defined $val;
            return defined $key ? $Nephia::Core::CONTEXT->{$key} : $Nephia::Core::CONTEXT;
        };
        $plugin->import if $plugin->can('import');
        $plugin->load($pkg, $opt) if $plugin->can('load');

        for my $func ( @{"${plugin}::EXPORT"} ){
            *{"$pkg\::$func"} = $plugin->can($func);
        }
        if (my $plugin_action = $plugin->can('before_action')) {
            my $orig = Nephia::Core->can('before_action');
            *Nephia::Core::before_action = sub {
                my ($env, $path_param, $action) = @_;
                $plugin_action->($env, $path_param, $orig, $action);
            };
        }
        for my $func (qw/process_env process_response process_content/) {
            my $plugin_func = $plugin->can($func);
            if ($plugin_func) {
                my $orig = Nephia::Core->can($func);
                my $sub = sub {
                    my $in = shift;
                    my $out = $plugin_func->($orig->($in));
                    return $out;
                }; 
                *{'Nephia::Core::'.$func} = $sub;
            }
        }
    }
}

1;
