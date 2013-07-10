use strict;
use warnings;
use utf8;
use Test::More;

use Nephia::Core;
pass 'Nephia::Core loaded';

my @plugins = Nephia::Core::normalize_plugin_names(qw/Hoge +Piyo::Piyo/);
is_deeply \@plugins, [qw/Nephia::Plugin::Hoge Piyo::Piyo/];

done_testing;
