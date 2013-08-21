use strict;
use warnings;
use Test::More;
use PrimalNephia::PluginLoader;

is PrimalNephia::PluginLoader::_normalize_plugin_name('Hoge'), 'PrimalNephia::Plugin::Hoge', '_normalize_plugin_name Hoge';
is PrimalNephia::PluginLoader::_normalize_plugin_name('+Piyo::Piyo'), 'Piyo::Piyo', '_normalize_plugin_name +Piyo::Piyo';

done_testing;
