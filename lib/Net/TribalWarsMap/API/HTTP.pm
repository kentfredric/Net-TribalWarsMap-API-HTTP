
use strict;
use warnings;

package Net::TribalWarsMap::API::HTTP;

# ABSTRACT: HTTP User Agent For L<< C<TribalWarsMap.com>|http://tribalwarsmap.com >>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Net::TribalWarsMap::API::HTTP",
    "interface":"class",
    "inherits":"Moo::Object"
}

=end MetaPOD::JSON

=cut

=head1 SYNOPSIS

This module is mostly a common shared component for a bunch of L<< C<TribalWarsMap.com>|http://tribalwarsmap.com >> C<API> Modules.

Its just a huge glue layer gluing together

=over 4

=item * L<< C<WWW::Mechanize::Cached>|WWW::Mechanize::Cached >>

=item * L<< C<HTTP::Tiny::Mech>|HTTP::Tiny::Mech >>

=item * L<< C<CHI>|CHI >>

=item * L<< C<Path::Tiny>|Path::Tiny >>

=item * L<< C<File::Spec>|File::Spec >>

=back

In order to produce

=over 4

=item * A Cached HTTP User Agent

=item * With a shared cache in C</tmp/perl-Net-TribalWarsMap-API.cache/>

=item * With a per instance key set for C</tmp/perl-Net-TribalWarsMap-API.cache/*>

=back

Usage:

    use Net::TribalWarsMap::API::HTTP;

    my $ua = Net::TribalWarsMap::API::HTTP->new(
        # /tmp/perl-Net-TribalWarsMap-API.cache/foo
        cache_name => 'foo'
    );

=cut

use Moo 1.000008;
use Path::Tiny qw(path);

=attr C<tmp_root>

=cut

has tmp_root => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    require File::Spec;
    return path( File::Spec->tmpdir );
  },
);

=attr C<tw_suffix>

=cut

has tw_suffix => (
  is      => ro =>,
  lazy    => 1,
  default => sub {
    'perl-Net-TribalWarsMap-API.cache';
  },
);

=attr C<tw_root>

=cut

has tw_root => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    my $p = $_[0]->tmp_root->child( $_[0]->tw_suffix );
    $p->mkpath;
    return $p;
  },
);

=attr C<cache_name>

=cut

has cache_name => (
  is       => ro =>,
  required => 1,
);

=attr C<chi>

=cut

has chi => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    require CHI;
    return CHI->new(
      driver     => 'File',
      root_dir   => $_[0]->tw_root->stringify,
      namespace  => $_[0]->cache_name,
      expires_in => '60 minutes',
    );
  },
);

=attr C<agent>

=cut

has agent => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    my ($self) = @_;
    if ( __PACKAGE__->VERSION ) {
      return __PACKAGE__ . q[/] . __PACKAGE__->VERSION;
    }
    return __PACKAGE__ . q[/dev];
  },
);

=attr C<mech>

=cut

has mech => (
  is      => ro => lazy => 1,
  builder => sub {
    require WWW::Mechanize::Cached;
    return WWW::Mechanize::Cached->new( cache => $_[0]->chi, agent => $_[0]->agent );
  },
);

=attr C<ht_tiny>

=cut

has 'ht_tiny' => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    require HTTP::Tiny::Mech;
    return HTTP::Tiny::Mech->new( mechua => $_[0]->mech, );
  },
);

=method C<get>

    my $result = $ua->get( $url );

See L<< C<HTTP::Tiny>|HTTP::Tiny >> and L<< C<HTTP::Tiny::Mech>|HTTP::Tiny::Mech >> for details

=cut

sub get {
  my ( $self, $url ) = @_;
  return $self->ht_tiny->get($url);
}

1;
