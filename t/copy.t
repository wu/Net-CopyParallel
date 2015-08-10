#!/perl
use strict;
use warnings;

use File::Temp qw/ :POSIX /;
use Test::Exception;
use Test::More;
use Test::Routine;
use Test::Routine::Util;
use YAML;

use Net::CopyParallel::Logger;
use Net::CopyParallel;
use Net::CopyParallel::Server;
use Net::CopyParallel::Source;

my $log4perl = Net::CopyParallel::Logger->new();
$log4perl->init();

has copier => (
    is   => 'ro',
    lazy => 1,
    clearer => 'reset_copier',
    default => sub {
        my $self = shift;
        return Net::CopyParallel->new( servers       => $self->servers,
                                       source        => $self->source,
                                       command_tmpl  => 'echo foo',
                                       maxiterations => 9,
                                       dryrun        => 1,
                                       cascade       => 1,
                                   );
    },
);

has source => (
    is => 'ro',
    lazy => 1,
    clearer => 'reset_source',
    default => sub {
        my ($fh, $file) = tmpnam();
        print $fh "foo";
        close $fh or die "Error closing file: $!\n";
        return Net::CopyParallel::Source->new( { path => $file } );
    },
);

has servers => (
    is => 'rw',
    lazy => 1,
    clearer => 'reset_servers',
    default => sub {
        my $self = shift;

        my $localhost = Net::CopyParallel::Server->new( { hostname  => 'localhost',
                                                         has_source => 1,
                                                         started    => 1,
                                                     } );
        my $server = Net::CopyParallel::Server->new( { hostname => 'testhost1' } );

        return [ $localhost, $server ]
    }
);

test "create an instance of Net::CopyParallel" => sub {
    my ($self) = @_;

    $self->reset_copier; # this test requires a fresh one

    ok( $self->copier,
        "Checking that we created an instance of Net::CopyParallel"
    );
};

test "copy one file to one target" => sub {
    my ($self) = @_;

    $self->reset_copier; # this test requires a fresh one

    {
        ok( my $status_h = $self->copier->copy_step,
            "Stepping one iteration into the copy"
        );

        is_deeply( $status_h,
                   {
                       available  => { localhost => 1 },
                       has_source => { localhost => 1 },
                       remaining  => 1,
                       started    => { localhost => 'testhost1' },
                       unstarted  => { 'testhost1' => 1 },
                   },
                   "Checking that file copy was initiated"
               );
    }

    {
        ok( my $status_h = $self->copier->copy(),
            "Running copy to completion"
        );

        is_deeply( $status_h,
                   {
                       available  => { localhost => 1, testhost1 => 1 },
                       has_source => { localhost => 1, testhost1 => 1 },
                       remaining  => 0,
                       ended      => 1,
                       unstarted  => {},
                   },
                   "Checking that file copy was complete"
               );
    }
};

test "copy one file to 10 targets" => sub {
    my ($self) = @_;

    $self->reset_copier; # this test requires a fresh one

    my @servers;
    push @servers,  Net::CopyParallel::Server->new( { hostname   => 'localhost',
                                                      has_source => 1,
                                                      started    => 1,
                                                  } );

    for my $idx ( 0 .. 9 ) {
        push @servers, Net::CopyParallel::Server->new( { hostname => "testhost$idx" } );
    }

    $self->servers( \@servers );

    my $status_h = $self->copier->copy();

    ok( $status_h->{ended},
        "Confirming that process ended"
    );

    is( scalar keys %{ $status_h->{has_source} },
        11,
        "Checking that all 11 hosts have the source"
    );

    is( scalar keys %{ $status_h->{available} },
        11,
        "Checking that all 11 hosts are all available"
    );

};

test "detect no has_source server" => sub {
    my ($self) = @_;

    $self->reset_copier; # this test requires a fresh one

    my @servers;
    push @servers, Net::CopyParallel::Server->new( { hostname => "server1" } );
    push @servers, Net::CopyParallel::Server->new( { hostname => "server2" } );
    push @servers, Net::CopyParallel::Server->new( { hostname => "server3" } );

    $self->servers( \@servers );

    throws_ok
        { $self->copier->copy_step }
        qr/no source/,
        'detect when no server is has_source';
};

run_me;
done_testing;
