#!/perl
use strict;
use warnings;

use File::Temp qw/ :POSIX /;
use Test::More;
use Test::Routine;
use Test::Routine::Util;
use YAML;

use Net::CopyParallel::Logger;
use Net::CopyParallel::Command;
use Net::CopyParallel::Queue;
use Net::CopyParallel::Server;
use Net::CopyParallel::Source;
use Net::CopyParallel::Xfer;

my $log4perl = Net::CopyParallel::Logger->new();
$log4perl->init( 'INFO' );

has xfer => (
    is   => 'ro',
    lazy => 1,
    clearer => 'reset_xfer',
    default => sub {
        my $queue  = Net::CopyParallel::Queue->new();
        my $source_server = Net::CopyParallel::Server->new( {hostname => 'localhost', queue => $queue} );
        my $target_server = Net::CopyParallel::Server->new( {hostname => 'foohost',   queue => $queue} );

        my ($fh, $file) = tmpnam();
        print $fh "testing\n";
        close $fh;
        my $source = Net::CopyParallel::Source->new( { path => $file } );

        return Net::CopyParallel::Xfer->new( { source_server => $source_server,
                                               target_server => $target_server,
                                               command       => Net::CopyParallel::Command->new( { command => ["/bin/true"] } ),
                                               source        => $source,
                                          });
    },
);

test "create an instance of Net::CopyParallel::Xfer" => sub {
    my ($self) = @_;

    $self->reset_xfer; # this test requires a fresh one

    ok( $self->xfer,
        "Checking that we created an instance of Net::CopyParallel::Xfer"
    );

};

test "starting an xfer marks all items as 'running'" => sub {
    my ($self) = @_;

    $self->reset_xfer; # this test requires a fresh one

    ok( $self->xfer->start(),
        "Calling start() on transfer"
    );

    sleep 1;

    ok( $self->xfer->check_status(),
        "Checking that xfer marked as 'running'"
    );
};

test "build commands" => sub {
    my ( $self ) = @_;

    my $queue  = Net::CopyParallel::Queue->new();

    my ($fh, $file) = tmpnam();
    my $source = Net::CopyParallel::Source->new( { path => $file } );

    is_deeply( Net::CopyParallel::Xfer->new(
                   { source_server => Net::CopyParallel::Server->new( {hostname => 'localhost', queue => $queue} ),
                     target_server => Net::CopyParallel::Server->new( {hostname => 'foohost',   queue => $queue} ),
                     source        => $source, } )->_build_command()->command,
               [ "scp", $file, "foohost:$file" ],
               "Checking build_command for simple scp from localhost to foohost"
           );

    is_deeply( Net::CopyParallel::Xfer->new(
                   { source_server => Net::CopyParallel::Server->new( {hostname => 'localhost', queue => $queue} ),
                     target_server => Net::CopyParallel::Server->new( {hostname => 'foohost',   queue => $queue} ),
                     source        => $source,
                     dryrun        => 1 } )->_build_command()->command,
               [ "ssh", "foohost", "hostname" ],
               "Checking build_command for dryrun from localhost"
           );

    is_deeply( Net::CopyParallel::Xfer->new(
                   { source_server => Net::CopyParallel::Server->new( {hostname => 'foohost', queue => $queue} ),
                     target_server => Net::CopyParallel::Server->new( {hostname => 'barhost', queue => $queue} ),
                     source        => $source, } )->_build_command()->command,
               [ "ssh", '-A', '-x', 'foohost', "scp", $file, "barhost:$file" ],
               "Checking build_command for scp initiated from remote host"
           );

    is_deeply( Net::CopyParallel::Xfer->new(
                   { source_server => Net::CopyParallel::Server->new( {hostname => 'foohost', queue => $queue} ),
                     target_server => Net::CopyParallel::Server->new( {hostname => 'barhost', queue => $queue} ),
                     source        => $source,
                     dryrun        => 1 } )->_build_command()->command,
               [ "ssh", '-A', '-x', 'foohost', "ssh", 'barhost', "hostname" ],
               "Checking build_command for dryrun from remote host"
           );

};

run_me;
done_testing;
