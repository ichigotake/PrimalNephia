package PrimalNephia::TestPluginApp;
use strict;
use warnings;
use utf8;
use PrimalNephia plugins => [qw/Bark/, 'Macopy' => {wei => 'うぇーい'}];

our $VERSION = 0.37;

path '/bark' => sub {
    bark();
};

path '/wei' => sub {
    wei();
};

1;
__END__

=head1 NAME

PrimalNephia-TestApp - Test Web Application for PrimalNephia

=head1 SYNOPSIS

  $ plackup

=head1 DESCRIPTION

PrimalNephia::TestApp is web application based PrimalNephia.

=head1 AUTHOR

ytnobody

=head1 SEE ALSO

PrimalNephia

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
