#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../lib";

use Raisin::API;
use Types::Standard qw(Int Str);

my %USERS = (
    1 => {
        name => 'Darth Wader',
        password => 'deathstar',
        email => 'darth@deathstar.com',
    },
    2 => {
        name => 'Luke Skywalker',
        password => 'qwerty',
        email => 'l.skywalker@jedi.com',
    },
);

plugin 'APIDocs';

namespace user => sub {
    params [
        optional => { name => 'start', type => Int, default => 0, desc => 'Pager (start)' },
        optional => { name => 'count', type => Int, default => 0, desc => 'Pager (count)' },
    ],
    desc => 'List users',
    get => sub {
        my $params = shift;

        my @users
            = map { { id => $_, %{ $USERS{$_} } } }
              sort { $a <=> $b } keys %USERS;

        my $max_count = scalar(@users) - 1;
        my $start = $params->{start} > $max_count ? $max_count : $params->{start};
        my $count = $params->{count} > $max_count ? $max_count : $params->{count};

        my @slice = @users[$start .. $count];
        { data => \@slice }
    };

    desc 'List all users at once',
    get => 'all' => sub {
        my @users
            = map { { id => $_, %{ $USERS{$_} } } }
              sort { $a <=> $b } keys %USERS;
        { data => \@users }
    };

    params [
        requires => { name => 'name', type => Str, desc => 'User name' },
        requires => { name => 'password', type => Str, desc => 'User password' },
        optional => { name => 'email', type => Str, default => undef, regex => qr/.+\@.+/, desc => 'User email' },
    ],
    desc => 'Create new user',
    post => sub {
        my $params = shift;

        my $id = max(keys %USERS) + 1;
        $USERS{$id} = $params;

        { success => 1 }
    };

    route_param { name => 'id', type => Int, desc => 'User ID' },
    sub {
        desc 'Show user',
        get => sub {
            my $params = shift;
            $USERS{ $params->{id} };
        };
    };
};

run;
