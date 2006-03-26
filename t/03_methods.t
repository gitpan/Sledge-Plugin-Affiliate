use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    eval "use Sledge::TestPages;use Sledge::Cache::FastMmap;";
    plan $@ ? (skip_all => 'needs Sledge::TestPages, Sledge::Cache::FastMmap for testing') : (tests => 10);
}

package Mock::Pages;
use base qw(Sledge::TestPages);
use Sledge::Plugin::Affiliate;
use Sledge::Plugin::Cache;

__PACKAGE__->add_trigger(AFTER_DISPATCH => sub { shift->redirect('/') });

sub create_cache { Sledge::Cache::FastMmap->new(shift) }

sub dispatch_cache {
    my $self = shift;

    $self->affiliate->get_from_request;
    ::is_deeply $self->affiliate->get, {name => 'mock', session_id => 'ABCDEFG'}, 'get sender from request';
    $self->affiliate->store_to_cache('keyy');
    $self->session->remove($_) for $self->session->param;
    ::is_deeply $self->affiliate->get, undef, 'affiliate was removed';
    $self->affiliate->load_from_cache('keyy');
    ::is_deeply $self->affiliate->get, {name => 'mock', session_id => 'ABCDEFG'}, 'load from cache';

    ::throws_ok {$self->affiliate->store_to_cache} 'Sledge::Exception::ArgumentTypeError', 'store_to_cache with no argument';
    ::throws_ok {$self->affiliate->load_from_cache} 'Sledge::Exception::ArgumentTypeError', 'load_from_cache with no argument';
}

sub dispatch_gen_url {
    my $self = shift;
    $self->affiliate->get_from_request;

    ::is $self->affiliate->_get_url, 'http://www.example.com/?session_id=ABCDEFG&ad_id=jklj3m43uuk', 'generate url';
}

sub dispatch_gen_url_uniq {
    my $self = shift;
    $self->affiliate->get_from_request;

    ::is $self->affiliate->_get_url(unique_id => 'ho ge'), 'http://www.example.com/?session_id=ABCDEFG&ad_id=jklj3243uuk&unique_id=ho%20ge', 'generate url';
}

sub dispatch_send_notice {
    my $self = shift;
    $self->affiliate->get_from_request;
    #::is $self->affiliate->send_notice->code, 200, 'send notice';
}

sub dispatch_get_from_request {
    my $self = shift;

    $self->affiliate->get_from_request;
    ::is_deeply $self->affiliate->get, {name => 'mock', session_id => 'ABCDEFG'}, 'get sender from request';
}

sub dispatch_as_string {
    my $self = shift;

    ::is $self->affiliate->as_string, '', 'as_string empty';
    $self->affiliate->get_from_request;
    ::is $self->affiliate->as_string, 'mock=ABCDEFG', 'as_string';
}

package main;
my $d = $Mock::Pages::TMPL_PATH;
$Mock::Pages::TMPL_PATH = 't/';
my $c = $Mock::Pages::COOKIE_NAME;
$Mock::Pages::COOKIE_NAME = 'sid';
my $e = $Mock::Pages::AFFILIATE;
$Mock::Pages::AFFILIATE = {
    ua_opts => {
        agent   => 'Sledge::Plugin::Affiliate/0.01',
        timeout => 3,
    },
    sites => [
        {
            name  => 'mock',
            param => 's',
            url   => 'http://www.example.com/?session_id={SESSION_ID}&ad_id=jklj3m43uuk',
        }, {
            name  => 'mock_uniq',
            param => 's',
            url   => 'http://www.example.com/?session_id={SESSION_ID}&ad_id=jklj3243uuk&unique_id={UNIQUE_ID}',
        },
    ],
};
$ENV{HTTP_COOKIE}    = "sid=SIDSIDSIDSID";
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'aff_type=mock&s=ABCDEFG';

Mock::Pages->new->dispatch('get_from_request');
Mock::Pages->new->dispatch('cache');
Mock::Pages->new->dispatch('as_string');
Mock::Pages->new->dispatch('gen_url');
Mock::Pages->new->dispatch('send_notice');

$ENV{QUERY_STRING}   = 'aff_type=mock_uniq&s=ABCDEFG';
Mock::Pages->new->dispatch('gen_url_uniq');

