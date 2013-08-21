use strict;
use warnings;
use Test::More;

subtest normal => sub {
    use PrimalNephia::GlobalVars;
    PrimalNephia::GlobalVars->set( foo => 123, bar => { hoge => 'abc' } );
    my $foo = PrimalNephia::GlobalVars->get('foo');
    my $bar = PrimalNephia::GlobalVars->get('bar');
    my @baz = PrimalNephia::GlobalVars->get(qw/foo bar/);
    is( $foo, 123, 'simple scalar' );
    isa_ok( $bar, 'HASH' );
    is( $bar->{hoge}, 'abc', 'hash' );
    is( $baz[0], $foo, 'get scalar by list' );
    is_deeply( $baz[1], $bar, 'get hashref by list' );
};

subtest check_stored_as_singleton => sub {
    use PrimalNephia::GlobalVars;
    my $foo = PrimalNephia::GlobalVars->get('foo');
    my $bar = PrimalNephia::GlobalVars->get('bar');
    my @baz = PrimalNephia::GlobalVars->get(qw/foo bar/);
    is( $foo, 123, 'simple scalar' );
    isa_ok( $bar, 'HASH' );
    is( $bar->{hoge}, 'abc', 'hash' );
    is( $baz[0], $foo, 'get scalar by list' );
    is_deeply( $baz[1], $bar, 'get hashref by list' );
};

done_testing;

