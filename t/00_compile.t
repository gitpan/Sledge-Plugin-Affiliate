use strict;
use warnings;
use Test::More;

BEGIN {
    eval "use Sledge::Exceptions";
    plan $@ ? (skip_all => 'needs Sledge::Exceptions for testing') : (tests => 1);
}
sub register_hook { 'dummy for compile' }
BEGIN { use_ok 'Sledge::Plugin::Affiliate' }
