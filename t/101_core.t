use strict;
use warnings;
use utf8;
use Test::More;

use PrimalNephia::Core;
pass 'PrimalNephia::Core loaded';

can_ok __PACKAGE__, qw/
   get post put del path 
   req res param path_param nip 
   run config app 
   nephia_plugins base_dir 
   cookie set_cookie
/;

done_testing;
