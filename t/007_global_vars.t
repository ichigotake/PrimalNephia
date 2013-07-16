use strict;
use warnings;
use Test::More;

subtest normal => sub {
    use Nephia::GlobalVars;
    Nephia::GlobalVars->store( foo => 123, bar => { hoge => 'abc' } );
    is( Nephia::GlobalVars->foo, 123, 'simple scalar' );
    isa_ok( Nephia::GlobalVars->bar, 'HASH' );
    is( Nephia::GlobalVars->bar->{hoge}, 'abc', 'hash' );
};

subtest check_stored_as_singleton => sub {
    use Nephia::GlobalVars;
    is( Nephia::GlobalVars->foo, 123, 'simple scalar' );
    isa_ok( Nephia::GlobalVars->bar, 'HASH' );
    is( Nephia::GlobalVars->bar->{hoge}, 'abc', 'hash' );
};

done_testing;

