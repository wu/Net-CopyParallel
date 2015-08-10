#!/perl
use strict;
use warnings;

use Test::More;
use Test::Routine;
use Test::Routine::Util;

use Net::CopyParallel::Duration;

has duration => (
    is   => 'ro',
    lazy => 1,
    clearer => 'reset_duration',
    default => sub {
        return Net::CopyParallel::Duration->new();
    },
);

test "create an instance of Net::CopyParallel::Duration" => sub {
    my ($self) = @_;
    $self->reset_duration; # this test requires a fresh one

    ok( $self->duration,
        "Checking that we created an instance of Net::CopyParallel::Duration"
    );
};

test "get_runtime_string" => sub {
    my ( $self ) = @_;

    is( $self->duration->format( 0 ),
        "0s",
        "0s"
    );

    is( $self->duration->format( 1 ),
        "1s",
        "1 second"
    );

    is( $self->duration->format( 60 ),
        "1m",
        "1 minute"
    );

    is( $self->duration->format( 61 ),
        "1m 1s",
        "1 minute 1 second"
    );

    is($self->duration->format( 3600 ),
        "1h",
        "1 hour"
    );

    is( $self->duration->format( 3660 ),
        "1h 1m",
        "1 hour 1 minute"
    );

    is( $self->duration->format( 3661 ),
        "1h 1m 1s",
        "1 hour 1 minute 1 second"
    );

    is( $self->duration->format( 3600 * 55 + 60 * 5 + 5 ),
        "55h 5m 5s",
        "5 hours 5 minutes 5 seconds"
    );
};

run_me;
done_testing;
