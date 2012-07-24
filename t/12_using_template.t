use strict;
use warnings;
use Test::More;
use Plack::Test;
use Nephia::TestApp;
use HTTP::Request::Common;
use JSON;
use t::Util;

test_psgi 
    app => Nephia::TestApp->run( test_config ),
    client => sub {
        my $cb = shift;

        subtest "normal request" => sub {
            my $res = $cb->(GET "/");
            is $res->code, 200;
            is $res->content_type, 'text/html';
            is $res->content_length, 211;
            like $res->content, qr/Nephia::TestApp/;
        };
    }
;

done_testing;
