#!/perl
use strict;
use warnings;

use Log::Log4perl;
use Test::More;
use Test::Routine;
use Test::Routine::Util;
use YAML;

use Net::CopyParallel::Command;

test "run a command that succeeds" => sub {
    my ($self) = @_;

    ok( my $command = Net::CopyParallel::Command->new( { command => [ 'echo', 'testfoo' ] } ),
        "Creating a new command object"
    );

    ok( $command->start(),
        "Running command"
    );

    sleep 1;

    ok( my $results_h = $command->get_results(),
        "Getting results\n"
    );

    is_deeply( $results_h->{output},
               [ 'testfoo' ],
               "Checking command output"
           );

    is( $results_h->{exit},
        0,
        "Checking command exit status"
    );
};

test "run a command that fails" => sub {
    my ($self) = @_;

    ok( my $command = Net::CopyParallel::Command->new( { command => ['/bin/false'] } ),
        "Creating a new command object"
    );

    ok( $command->start(),
        "Running command"
    );

    sleep 1;

    ok( my $results_h = $command->get_results(),
        "Getting results\n"
    );

    is_deeply( $results_h->{output},
               [ ],
               "Checking command output"
           );

    is( $results_h->{exit},
        1,
        "Checking command exit status"
    );
};

test "run a command that is incomplete" => sub {
    my ($self) = @_;

    ok( my $command = Net::CopyParallel::Command->new( { command => ['sleep', '3'] } ),
        "Creating a new command object"
    );

    ok( $command->start(),
        "Running command"
    );

    ok( ! $command->get_results(),
        "Checking that command is still running"
    );
};


test "calling get_results a second time" => sub {
    my ($self) = @_;

    ok( my $command = Net::CopyParallel::Command->new( { command => ['echo', 'foo'] } ),
        "Creating a new command object"
    );

    ok( $command->start(),
        "Running command"
    );

    sleep 1;

    ok( my $results1_h = $command->get_results(),
        "Getting results\n"
    );

    ok( my $results2_h = $command->get_results(),
        "Getting results a second time\n"
    );

    is_deeply( $results1_h,
               $results2_h,
               "Calling results multiple times gives the same results"
           );
};

test "check if a command was started" => sub {
    my ($self) = @_;

    my $command = Net::CopyParallel::Command->new( { command => ['sleep', '3'] } );

    ok( ! $command->is_started,
        "Checking that command was not yet started"
    );

    ok( $command->start(),
        "Starting command"
    );

    ok( $command->is_started,
        "Checking that command was started"
    );
};

test "check if a command was finished" => sub {
    my ($self) = @_;

    my $command = Net::CopyParallel::Command->new( { command => ['sleep', '2'] } );

    ok( ! $command->is_finished,
        "Checking command that is not started is not finished"
    );

    ok( $command->start(),
        "Starting command"
    );

    ok( ! $command->is_finished,
        "Checking command that is running is not finished"
    );

    sleep 3;

    ok( $command->is_finished,
        "Checking that command is finished"
    );
};

run_me;
done_testing;
