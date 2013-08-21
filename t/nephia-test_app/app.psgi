use strict;
use warnings;
use FindBin;
use Plack::Builder;

use lib ("$FindBin::Bin/lib", "$FindBin::Bin/extlib/lib/perl5");
use PrimalNephia::TestApp;
builder {
    enable 'ContentLength';
    PrimalNephia::TestApp->run({
        view => {
            include_path => [ 't/nephia-test_app/view' ],
        },
    });
};
