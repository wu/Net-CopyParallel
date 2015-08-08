package Net::CopyParallel::CLI;

use Moo;
use namespace::clean;

use Net::CopyParallel::Server;
use Net::CopyParallel::Orchestrator;
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

    my @servers;
    push @servers, Net::CopyParallel::Server->new( {
        hostname   => 'localhost',
        available  => 1,
        sourceable => 1,
        started    => 1,
    } );
    for my $host ( split /,/, $self->options->{hosts} ) {
        next if $host eq "localhost";
        push @servers, Net::CopyParallel::Server->new( { hostname => $host } );
    }

    use YAML;
    print "\n\n";
    print YAML::Dump { servers => \@servers };
    print "\n\n";

    my $source = Net::CopyParallel::Source->new( path => $self->options->{path} );;

    my $queue = Net::CopyParallel::Queue->new( );

    $self->logger->info( "Creating a new orchestrator" );
    my $orchestrator = Net::CopyParallel::Orchestrator->new( {
        servers => \@servers,
        queue  => $queue,
        source => $source,
    } );

    $self->logger->info( "Copying..." );
    $orchestrator->copy();

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
            '-p|path:s'   => \$options->{path},
            '-help|?'	  => \$options->{help},
        ) ) {
        $self->logger->logdie( "ERROR: unable to parse command line options!" );
    }

    unless ( $options->{hosts} ) {
        $self->logger->logdie( "ERROR: host not specified, use -hosts" );
    }

    unless ( $options->{path} ) {
        $self->logger->logdie( "ERROR: host not specified, use -hosts" );
    }

    return $options;
}

1;
