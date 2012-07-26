package Nephia::Setup;
use strict;
use warnings;
use Class::Load ':all';

sub create {
    my ( $class, $flavor ) = @_;
    $flavor ||= 'Default';
    my $klass = join( '::', __PACKAGE__, $flavor );
    load_class( $klass );
    {
        no strict 'refs';
        &{$klass."::create"}( $class );
    }
}

1;
