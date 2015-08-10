#!/perl
use strict;
use warnings;

use Test::More;
use Test::Routine;
use Test::Routine::Util;

use Net::CopyParallel::EventLog;

has eventlog => (
    is   => 'ro',
    lazy => 1,
    clearer => 'reset_eventlog',
    default => sub {
        return Net::CopyParallel::EventLog->new();
    },
);

test "create an instance of Net::CopyParallel::EventLog" => sub {
    my ($self) = @_;

    $self->reset_eventlog; # this test requires a fresh one

    ok( $self->eventlog,
        "Checking that we created an instance of Net::CopyParallel::EventLog"
    );
};

test "get event log history" => sub {
    my ($self) = @_;

    $self->reset_eventlog; # this test requires a fresh one

    my $time = time;
    my $date = scalar localtime $time;

    ok( $self->eventlog->log_event( { date => 1, elapsed => 2, status => 3, source => 4, target => 5 } ),
        "Logging first event"
    );

    ok( $self->eventlog->log_event( { date => 6, elapsed => 7, status => 8, source => 9, target => 10 } ),
        "Logging second event"
    );

    is_deeply( [ $self->eventlog->display_history() ],
               [ '1, 2, 3, 4, 5', '6, 7, 8, 9, 10' ],
               "Getting event history",
           );
};

run_me;
done_testing;
