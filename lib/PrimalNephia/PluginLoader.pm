package PrimalNephia::PluginLoader;
use strict;
use warnings;
use Module::Load ();

sub load {
    my $caller = caller();
    my @plugins = @_;

    while (@plugins) {
        my $plugin = _normalize_plugin_name(shift(@plugins));
        my $opt    = $plugins[0] && ref $plugins[0] ? shift(@plugins) : undef;
        _export_plugin_functions($plugin, $caller, $opt);
    }
};

sub _normalize_plugin_name {
    local $_ = shift;
    /^\+/ ? s/^\+// && $_ : "PrimalNephia::Plugin::$_";
}

sub _export_plugin_functions {
    my ($plugin, $pkg, $opt) = @_;

    Module::Load::load($plugin);
    {
        no strict   qw/refs subs/;
        no warnings qw/redefine prototype/;

        *{$plugin.'::context'} = *PrimalNephia::Core::context;
        *{$plugin.'::plugin_config'} = sub (;$) { $_[0] ? $opt->{$_[0]} : $opt };
        $plugin->import           if $plugin->can('import');
        $plugin->load($pkg, $opt) if $plugin->can('load');

        *{"$pkg\::$_"} = $plugin->can($_) for @{"${plugin}::EXPORT"};
    }
    _load_hook_point($plugin);
}

sub _load_hook_point {
    my $plugin = shift;
    {
        no strict   qw/refs/;
        no warnings qw/redefine/;
        if (my $plugin_action = $plugin->can('before_action')) {
            my $orig = PrimalNephia::Core->can('before_action');
            *PrimalNephia::Core::before_action = sub {
                my ($env, $path_param, $action) = @_;
                $plugin_action->($env, $path_param, $orig, $action);
            };
        }
        for my $func (qw/process_env process_response process_content/) {
            my $plugin_func           = $plugin->can($func) or next;
            my $orig                  = PrimalNephia::Core->can($func);
            *{'PrimalNephia::Core::'.$func} = sub { $plugin_func->($orig->(shift)) }; 
        }
    }
}

1;
