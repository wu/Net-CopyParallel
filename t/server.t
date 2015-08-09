#!/perl
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Routine;
use Test::Routine::Util;

use Net::CopyParallel::Logger;
use Net::CopyParallel::Server;

has server => (
    is   => 'ro',
    lazy => 1,
    clearer => 'reset_server',
    default => sub {
        my $self = shift;
        return Net::CopyParallel::Server->new( { hostname => $self->hostname } );
    },
);

has hostname => (
    is   => 'rw',
    lazy => 1,
    clearer => 'reset_hostname',
    default => "foohost",
);

test "create an instance of Net::CopyParallel::Server" => sub {
    my ($self) = @_;

    $self->reset_server; # this test requires a fresh one

    ok( $self->server,
        "Checking that we created an instance of Net::CopyParallel::Server"
    );

};

test "checking hostname" => sub {
    my ($self) = @_;

    $self->reset_server; # this test requires a fresh one

    is( $self->server->hostname,
        $self->hostname,
        "Checking that server was created with proper hostname"
    );
};

test "don't allow blank hostnames" => sub {
    my ( $self ) = @_;

    $self->reset_server; # this test requires a fresh one
    $self->hostname('');

    throws_ok { $self->server->hostname } qr/hostname can\'t be blank/,
                 "Checking for error when using blank hostname";

};

run_me;
done_testing;
