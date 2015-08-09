package Net::CopyParallel::CLI;

use Moo;
use namespace::clean;

use Net::CopyParallel;
use Net::CopyParallel::Logger;
use Net::CopyParallel::Server;
use Net::CopyParallel::Queue;
use Net::CopyParallel::Source;

use Getopt::Long;
use Log::Log4perl;

has argv => (
    is => 'ro',
    required => 1,
);

has options => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        return $self->parse_command_line_options( $self->argv );
    }
);

has 'logger'  => (
    is => 'ro',
    lazy => 1,
    default => sub {
        return Log::Log4perl::get_logger( __PACKAGE__ );
    },
);


sub run {
    my ( $self ) = @_;

    # lazy load options first, to initialize logging
    $self->options;

    my @servers;
    push @servers, Net::CopyParallel::Server->new( {
        hostname   => 'localhost',
        available  => 1,
        has_source => 1,
        started    => 1,
    } );
    for my $host ( split /,/, $self->options->{hosts} ) {
        next if $host eq "localhost";
        push @servers, Net::CopyParallel::Server->new( { hostname => $host } );
    }

    my $source = Net::CopyParallel::Source->new( path => $self->options->{path} );;

    my $queue = Net::CopyParallel::Queue->new( );

    $self->logger->info( "Creating a new Net::CopyParallel object" );
    my $copier = Net::CopyParallel->new( {
        servers => \@servers,
        queue   => $queue,
        source  => $source,
        cascade => $self->options->{cascade},
    } );

    $self->logger->info( "Copying..." );
    $copier->copy();

    $self->logger->info( "Finished copying..." );
}

sub parse_command_line_options {
    my ( $self ) = @_;

    my $options;

    unless (
        Getopt::Long::GetOptionsFromArray(
            $self->argv,
            '-v|verbose!' => \$options->{verbose},
            '-h|hosts:s'  => \$options->{hosts},
            '-c|cascade!' => \$options->{cascade},
            '-n|dryrun'   => \$options->{dryrun},
            '-p|path:s'   => \$options->{path},
            '-help|?'	  => \$options->{help},
        ) ) {
        $self->logger->logdie( "ERROR: unable to parse command line options!" );
    }

    my $log4perl = Net::CopyParallel::Logger->new();
    my $loglevel = $options->{debug} ? 'DEBUG' : $options->{verbose} ? 'INFO' : 'WARN';
    $log4perl->init( $loglevel );

    unless ( $options->{hosts} ) {
        $self->logger->logdie( "ERROR: host not specified, use -hosts" );
    }

    unless ( $options->{path} ) {
        $self->logger->logdie( "ERROR: host not specified, use -hosts" );
    }

    return $options;
}

1;
