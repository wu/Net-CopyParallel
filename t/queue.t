#!/perl
use strict;
use warnings;

use File::Temp qw/ :POSIX /;
use Test::More;
use Test::Routine;
use Test::Routine::Util;
use YAML;

use Net::CopyParallel::Logger;
use Net::CopyParallel::Queue;
use Net::CopyParallel::Server;
use Net::CopyParallel::Source;
use Net::CopyParallel::Xfer;

my $log4perl = Net::CopyParallel::Logger->new();
$log4perl->init( 'INFO' );

has queue => (
    is   => 'ro',
    lazy => 1,
    clearer => 'reset_queue',
    default => sub {
        my $self = shift;
        return Net::CopyParallel::Queue->new();
    },
);

has xfer => (
    is   => 'ro',
    lazy => 1,
    clearer => 'reset_xfer',
    default => sub {
        my $self = shift;
        my $server1 = Net::CopyParallel::Server->new( { hostname => 'localhost', queue => $self } );
        my $server2 = Net::CopyParallel::Server->new( { hostname => 'foohost',   queue => $self } );

        my ($fh, $file) = tmpnam();
        print $fh "testing\n";
        close $fh;
        my $source  = Net::CopyParallel::Source->new( { path => $file } );

        my $xfer = Net::CopyParallel::Xfer->new( {
            source_server => $server1,
            target_server => $server2,
            source        => $source,
            command_tmpl  => '/bin/true',
        });

        return $xfer;
    },
);

test "create an instance of Net::CopyParallel::Queue" => sub {
    my ($self) = @_;

    $self->reset_queue; # this test requires a fresh one

    ok( $self->queue,
        "Checking that we created an instance of Net::CopyParallel::Queue"
    );
};

test "add a command to the queue" => sub {
    my ($self) = @_;

    $self->reset_queue; # this test requires a fresh one

    for my $count ( 1 .. 3 ) {
        is( $self->queue->enqueue( $self->xfer ),
            $count,
            "Checking item got new id: $count"
        );
    }
};

test "queue length" => sub {
    my ($self) = @_;

    $self->reset_queue; # this test requires a fresh one

    for my $count ( 1 .. 3 ) {
        ok( $self->queue->enqueue( $self->xfer ),
            "Adding an item to the queue"
        );

        is( $self->queue->get_queue_length(),
            $count,
            "Checking queue length for $count"
        );
    }

};

test "calling process the queue" => sub {
    my ($self) = @_;

    $self->reset_queue; # this test requires a fresh one

    is( $self->queue->enqueue( $self->xfer ),
        1,
        "Adding first item to the queue gets id 1"
    );

    ok( $self->queue->process(),
        "Calling process() on the queue"
    );
};

test "completed items are removed from the queue" => sub {
    my ( $self ) = @_;

    $self->reset_queue; # this test requires a fresh one

    is( $self->queue->enqueue( $self->xfer ),
        1,
        "Adding first item to the queue gets id 1"
    );

    ok( $self->queue->process(),
        "Calling process() on the queue to spawn processes"
    );

    sleep 1;

    ok( $self->queue->process(),
        "Calling process() on the queue to reap processes"
    );

    ok( ! scalar keys %{ $self->queue->queue },
        "Checking that no items are left in the queue"
    );
};

run_me;
done_testing;
