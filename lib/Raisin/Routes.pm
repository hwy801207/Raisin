package Raisin::Routes;

use strict;
use warnings;

use Carp;
use List::Util 'pairs';
use Raisin::Attributes;
use Raisin::Param;
use Raisin::Routes::Endpoint;

has 'cache' => {};
has 'list' => {};
has 'routes' => [];

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self;
}

# @args:
#   * [optional] named => []
#   * [optional] params => []
#   * [optional] path
#   * [required] code ref
sub add {
    my ($self, $method, $path, @args) = @_;
#use DDP { class => { expand => 0 } };
#p @args;

    if (!$method || !$path) {
        carp "Method and path are required";
        return;
    }

    my $code = pop @args;
    # Support only code as route destination
    if (!$code || !(ref($code) eq 'CODE')) {
        carp "Invalid route params for ${ uc $method } $path";
        return;
    }

    # Named route params
    if (scalar @args == 1 || scalar @args == 3) {
        $path = $path . '/' . pop @args;
    }

    my (@params, $desc);
    if (my %args = @args) {
        $desc = $args{desc};
        for my $key (qw(params named)) {
            for my $p (pairs @{ $args{$key} }) {
                push @params, Raisin::Param->new(
                    named => $key eq 'named',
                    type => $p->[0], # -> requires/optional
                    spec => $p->[1], # -> ['name', Int]
                );
            }
        }
    }

    if (ref($path) && ref($path) ne 'Regexp') {
        carp "Route `$path` should be SCALAR or Regexp";
        return;
    }

    if (!ref($path)) {
        $path =~ s{(.+)/$}{$1};
    }

    my $ep
        = Raisin::Routes::Endpoint->new(
            code => $code,
            desc => $desc,
            method => $method,
            params => \@params,
            path => $path,
        );
    push @{ $self->{routes} }, $ep;

    if ($self->list->{$method}{$path}) {
        carp "Route `$path` via `$method` is redefined";
    }
    $self->list->{$method}{$path} = scalar @{ $self->{routes} };
}

sub find {
    my ($self, $method, $path) = @_;

    my $cache_key = lc "$method:$path";
    my $routes
        = exists $self->cache->{$cache_key}
        ? $self->cache->{$cache_key}
        : $self->routes;

    my @found
    #   = sort { $b->bridge <=> $a->bridge || $a->pattern cmp $b->pattern }
        = grep { $_->match($method, $path) } @$routes;

    $self->cache->{$cache_key} = \@found;
    \@found;
}

1;

__END__

=head1 NAME

Raisin::Routes - Routing class for Raisin.

=head1 SYNOPSIS

    use Raisin::Routes;
    my $r = Raisin::Routes->new;

    my $params = { require => ['name', ], };
    my $code = sub { { name => $params{name} } }

    $r->add('GET', '/user', params => $params, $code);
    my $route = $r->find('GET', '/user');

=head1 DESCRIPTION

The router provides the connection between the HTTP requests and the web
application code.

=over

=item B<Adding routes>

    $r->add('GET', '/user', params => $params, $code);

=cut

=item B<Looking for a route>

    $r->find($method, $path);

=cut

=back

=head1 PLACEHOLDERS

Regexp

    qr#/user/(\d+)#

Required

    /user/:id

Optional

    /user/?id

=head1 METHODS

=head2 add

Adds a new route

=head2 find

Looking for a route

=head1 ACKNOWLEDGEMENTS

This module was inspired by L<Kelp::Routes>.

=cut
