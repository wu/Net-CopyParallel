package Net::CopyParallel;
use Moo;
use namespace::clean;

# VERSION

# ABSTRACT: copy files to remote servers in multiple locations

use Net::CopyParallel::Duration;
use Net::CopyParallel::Xfer;

use Log::Log4perl;

has source => (
    is => 'ro',
    isa => sub { die "must be Net::CopyParallel::Source" unless ref $_[0] eq "Net::CopyParallel::Source" },
    required => 1,
);

has servers => (
    is => 'ro',
    isa => sub { die "must be an array" unless ref $_[0] eq "ARRAY" },
    required => 1,
);

has cascade => (
    is => 'ro',
);

has queue => (
    is => 'ro',
    required => 1,
);

has dryrun => (
    is => 'ro',
);

has 'maxiterations' => (
    is => 'ro',
    default => 999999,
);

has iterations => (
    is => 'rw',
    default => 0,
);

has duration => (
    is => 'ro',
    lazy => 1,
    default => sub {
        return Net::CopyParallel::Duration->new();
    }
);

has 'logger'  => (
    is => 'ro',
    lazy => 1,
    default => sub {
        return Log::Log4perl::get_logger( __PACKAGE__ );
    },
);

has laststatus => (
    is => 'rw',
    default => '',
);
has laststatus_time => (
    is => 'rw',
    default => 0,
);

has starttime => (
    is => 'ro',
    default => sub { return time },
);

sub copy {
    my ( $self ) = @_;

    $self->logger->info( "Starting copy" );

    my $results;
    for ( 0 .. $self->maxiterations ) {
        $results = $self->copy_step();

        if ( $results->{ended} ) {
            $self->logger->info( "Ending copy" );
            return $results;
        }

        sleep 1;
    }

    $results->{maxiterations} = 1;
    $self->logger->fatal( "Reached maxiterations before ending, giving up..." );
    return $results;
}

sub copy_step {
    my ( $self ) = @_;

    my $iteration = $self->iterations + 1;
    $self->iterations( $iteration );

    $self->logger->info( "Starting copy step $iteration..." );

    my $status;
    my $index;
    my $num_active = 0;

    for my $server ( @{$self->servers} ) {
        $index->{ $server->{hostname} } = $server;
        my $hostname = $server->hostname;

        if ( $hostname eq "localhost" || $self->cascade ) {
            if ( $server->is_available ) {
                $status->{available}->{$server->hostname} = 1;
            }
        }
        if ( $server->has_source ) {
            $status->{has_source}->{$server->hostname} = 1;
        }
        if ( ! $server->started ) {
            $status->{unstarted}->{$server->hostname} = 1;
        }

        $num_active += $server->count_active_xfers();
    }

    my $num_has_source = $status->{has_source} ? scalar keys %{ $status->{has_source} } : 0;
    unless ( $num_has_source ) {
        $self->logger->logdie( "ERROR: no source" );
    }
    my $total_servers = scalar @{ $self->servers };
    $status->{remaining} = $total_servers - $num_has_source;

    my $num_unstarted = scalar keys %{$status->{unstarted}};
    my $num_available = scalar keys %{$status->{available}};

    my $now = time;
    my $runtime = $self->duration->format( $now - $self->starttime );

    my $status_msg = join( " ",
                           "active=$num_active",
                           "remaining=$status->{remaining}",
                           "unstarted=$num_unstarted",
                           "available_hosts=$num_available",
                           "source_hosts=$num_has_source",
                       );

    my $age = $now - $self->laststatus_time;
    if ( $status_msg eq $self->laststatus && $age < 15 ) {
        $self->logger->info( $status_msg );
    }
    else {
        $self->logger->warn( " ... [$runtime] " . $status_msg );
        $self->laststatus_time( $now );
        $self->laststatus( $status_msg );
    }

    if ( $status->{remaining} == 0 ) {
        $self->logger->warn( "Job complete in $runtime" );
        $status->{ended} = 1;
        return $status;
    }

    # check if there are any available hosts, and also any unstarted hosts
    if ( $num_available && $num_unstarted ) {
        # give one unstarted host to each available host
        my @unstarted = sort keys %{ $status->{unstarted} };
        for my $available ( sort keys %{ $status->{available} } ) {
            my $available_server = $index->{ $available };
            if ( scalar @unstarted ) {
                my $unstarted = pop @unstarted;
                my $unstarted_server = $index->{ $unstarted };

                my $xfer = Net::CopyParallel::Xfer->new(
                    source_server => $available_server,
                    target_server => $unstarted_server,
                    source        => $self->source,
                    dryrun        => $self->dryrun,
                );

                $self->queue->enqueue( $xfer );

                $status->{started}->{ $available } = $unstarted;
            }
        }
    }

    $self->queue->process();

    return $status;
}

1;
