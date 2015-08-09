#!/perl
use strict;
use warnings;

use File::Temp qw/ :POSIX tempdir /;
use Test::Exception;
use Test::More;
use Test::Routine;
use Test::Routine::Util;

use Net::CopyParallel::Logger;
use Net::CopyParallel::Source;

my $log4perl = Net::CopyParallel::Logger->new();
$log4perl->init();

has source => (
    is   => 'ro',
    lazy => 1,
    clearer => 'reset_source',
    default => sub {
        my $self = shift;
        my $sourcefile = join("/", $self->tempdir, "sourcefile");
        open(my $fh, ">", $sourcefile) or die "Couldn't open $sourcefile for writing: $!\n";
        print $fh "foo\n";
        close $fh or die "Error closing file: $!\n";
        return Net::CopyParallel::Source->new( { path => $sourcefile } );
    },
);

has tempdir => (
    is => 'ro',
    lazy => 1,
    clearer => 'reset_tempdir',
    default => sub {
        return tempdir( "/tmp/tmpdir-XXXXXXXXXX", CLEANUP => 1 );
    }
);

test "create an instance of Net::CopyParallel::Source" => sub {
    my ($self) = @_;

    $self->reset_source; # this test requires a fresh one

    ok( $self->source,
        "Checking that we created an instance of Net::CopyParallel::Source"
    );
};

test "detect non-existent source path" => sub {
    my ($self) = @_;

    my ($fh, $file) = tmpnam();
    close $fh;
    unlink $file;

    throws_ok
        { Net::CopyParallel::Source->new( { path => $file } ) }
        qr/Path not found/,
        "Detect when a source path does not exist";

};

test "detect if path not specified" => sub {
    my ($self) = @_;

    my ($fh, $file) = tmpnam();
    close $fh;
    unlink $file;

    throws_ok
        { Net::CopyParallel::Source->new() }
        qr/Missing required arguments\: path/,
        "Detect when a source path was not specified";

};

run_me;
done_testing;
