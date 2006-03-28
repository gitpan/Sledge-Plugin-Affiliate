package Sledge::Plugin::Affiliate;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
our $VERSION = '0.05';
use URI::Escape;
use LWP::UserAgent;

our $TYPE_PARAM   = 'aff_type';
our $SESSION_KEY  = '_s_affiliate';
our $CACHE_PREFIX = '_c_aff_';

sub import {
    my $self = shift;
    my $pkg  = caller;

    $pkg->register_hook(
        BEFORE_DISPATCH => sub {
            my $self = shift;
            $self->{affiliate} = Sledge::Plugin::Affiliate->new(page => $self);
        }
    );

    no strict 'refs';
    *{"$pkg\::affiliate"} = sub { shift->{affiliate} };
}

__PACKAGE__->mk_accessors(qw(page));

sub new {
    my $class = shift;
    return bless {@_}, $class;
}

sub set {
    my ($self, $name, $session_id) = @_;

    $self->page->session->param(
        $SESSION_KEY => {
            name       => $name,
            session_id => $session_id
        }
    );
}

sub get {
    my $self = shift;
    return $self->page->session->param($SESSION_KEY);
}

sub get_from_request { # xxx naming sense
    my $self = shift;

    my $param = $self->page->r->param($TYPE_PARAM) || '';
    my $sites = $self->_config->{sites};
    for my $site (@$sites) { # xxx hash?
        if ($param eq $site->{name}) {
            $self->set($site->{name} => $self->page->r->param($site->{param}));
        }
    }
}

sub _config {
    my $self = shift;
    return $self->page->create_config->affiliate;
}

sub send_notice {
    my $self = shift;
    my @opts = @_;

    return $self->_send($self->_get_url(@opts));
}

sub _get_url {
    my $self = shift;
    my @opts = @_;

    return unless $self->get; # no affiliate info

    my %config_for = map {$_->{name} => $_} @{$self->_config->{sites}};
    my $config = $config_for{$self->get->{name}};

    my %params = (
        session_id => $self->get->{session_id},
        @_
    );

    my $url = $config->{url};
    while (my ($key, $val) = each %params) {
        $url =~ s/\{\U$key\}/uri_escape($val)/ge;
    }

    return $url;
}

sub _send {
    my ($self, $url) = @_;

    my $ua = LWP::UserAgent->new(%{$self->_config->{ua_opts}});
    my $res = $ua->get($url);
    unless ($res->is_success) {
        Sledge::Exception::AffiliateError->throw($res->status_line . " : $url");
    }
    return $res;
}

sub store_to_cache {
    my $self = shift;
    my $key  = shift;

    Sledge::Exception::ArgumentTypeError->throw unless $key;

    $self->page->cache->param("$CACHE_PREFIX$key" => $self->get);
}

sub load_from_cache {
    my $self = shift;
    my $key  = shift;

    Sledge::Exception::ArgumentTypeError->throw unless $key;

    my $c = $self->page->cache->param("$CACHE_PREFIX$key");
    $self->set($c->{name} => $c->{session_id});
}

sub as_string {
    my $self = shift;

    return $self->get ? ($self->get->{name} .'='. $self->get->{session_id}) : '';
}

package Sledge::Exception::AffiliateError;
use base 'Sledge::Exception';
sub description { 'affiliate error' }

1;
__END__

=head1 NAME

Sledge::Plugin::Affiliate - easy to send notice request to affiliate site

=head1 SYNOPSIS

    package Your::Pages;
    use Sledge::Plugin::Affiliate;

    sub dispatch_index {
        my $self = shift;
        $self->affiliate->get_from_request;
    }

    sub dispatch_do_regist {
        my $self = shift;
        $self->affiliate->send_notice(unique_id => 'timpo at ma.la';
    }

    package Your::Config;
    $C{AFFILIATE} = {
        ua_opts => {
            agent   => 'Sledge::Plugin::Affiliate/0.01',
            timeout => 60,
        },
        sites => [
            {
                name  => 'ktaf',
                param => 'ktaf',
                url   => 'http://www.example.com/action-notice.cgi?a=ADM$KDDF&u={UNIQUE_ID}&r={SESSION_ID}',
            },
        ],
    };

=head1 DESCRIPTION

Sledge::Plugin::Affiliate is easy to send notice request to the affiliate site plugin, for Sledge.

=head1 METHODS

=head2 new

  Sledge::Plugin::Affiliate->new;

create new instance.

=head2 set

  $a->set('ktaf' => 'dsfau0JKLm');

save affiliate info to session.

=head2 get

  $a->get;

get the affiliate info from session.

=head2 get_from_request

  $a->get_from_request;

get the affiliate info from request, and save to session.

=head2 send_notice

  $a->send_notice;

send the notice request to affiliate site(e.g. L<http://ktaf.jp/>)

=head2 store_to_cache

  $a->store_to_cache;

copy affiliate info to cache(L<Sledge::Cache>).

=head2 load_from_cache

  $a->load_from_cache;

load affiliate info from cache.

=head2 as_string

  $a->as_string;

dump the affiliate info.

I suggest this string save to database before send notice message.

=head1 AUTHOR

MATSUNO Tokuhiro E<lt>tokuhiro at mobilefactory.jpE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Bundle::Sledge>

=cut
