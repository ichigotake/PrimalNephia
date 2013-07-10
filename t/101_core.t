use strict;
use warnings;
use utf8;
use Test::More;

use Nephia::Core;
pass 'Nephia::Core loaded';

my @raw    = qw/Hoge +Piyo::Piyo/;
my @plugins = Nephia::Core::normalize_plugin_names(@raw);
is_deeply \@plugins, [qw/Nephia::Plugin::Hoge Piyo::Piyo/];
is_deeply \@raw,     [qw/Hoge +Piyo::Piyo/];

done_testing;
