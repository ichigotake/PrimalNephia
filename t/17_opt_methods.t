use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common qw/ GET POST PUT DELETE /;
use JSON;
use utf8;
use Encode;

use lib qw( ./t/nephia-test_app/lib );
use Nephia::TestApp;
use t::Util;

test_psgi 
    app => Nephia::TestApp->run( test_config ),
    client => sub {
        my $cb = shift;

        subtest "get request" => sub {
            my $res = $cb->(GET "/item");
            is $res->code, 200;
            is $res->content_type, 'application/json';
            my $json = JSON->new->utf8->decode( $res->content );
            is $json->{message}, 'ひのきのぼう　が　ある。';
        };

        subtest "post request" => sub {
            my $res = $cb->(POST "/item" );
            is $res->code, 200;
            is $res->content_type, 'application/json';
            my $json = JSON->new->utf8->decode( $res->content );
            is $json->{message}, 'ひのきのぼう　で　かべをたたいた';
        };
        subtest "put request" => sub {
            my $res = $cb->(PUT "/item");
            is $res->code, 200;
            is $res->content_type, 'application/json';
            my $json = JSON->new->utf8->decode( $res->content );
            is $json->{message}, 'ひのきのぼう　を　もどした';
        };

        subtest "delete request" => sub {
            my $res = $cb->(DELETE "/item");
            is $res->code, 200;
            is $res->content_type, 'application/json';
            my $json = JSON->new->utf8->decode( $res->content );
            is $json->{message}, 'ひのきのぼう　を　すてた';
        };

    }
;

done_testing;
