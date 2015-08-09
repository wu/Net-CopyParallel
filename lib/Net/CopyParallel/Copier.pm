package Net::CopyParallel::Copier;

use Moo;
use namespace::clean;

use Net::CopyParallel::Xfer;

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

has queue => (
    is => 'ro',
    required => 1,
);

has 'maxiterations' => (
    is => 'ro',
    default => 999999,
);

has iterations => (
    is => 'rw',
    default => 0,
);

has 'logger'  => (
    is => 'ro',
    lazy => 1,
    default => sub {
        return Log::Log4perl::get_logger( __PACKAGE__ );
    },
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

    for my $server ( @{$self->servers} ) {
        $index->{ $server->{hostname} } = $server;

        if ( $server->is_sourceable ) {
            $status->{sourceable}->{$server->hostname} = 1;
        }
        if ( $server->is_available ) {
            $status->{available}->{$server->hostname} = 1;
        }
        if ( ! $server->started ) {
            $status->{unstarted}->{$server->hostname} = 1;
        }
    }

    my $num_sourceable = $status->{sourceable} ? scalar keys %{ $status->{sourceable} } : 0;
    unless ( $num_sourceable ) {
        die( "ERROR: no source" );
    }
    my $total_servers = scalar @{ $self->servers };
    $status->{remaining} = $total_servers - $num_sourceable;

    my $num_unstarted = scalar keys %{$status->{unstarted}};
    my $num_available = scalar keys %{$status->{available}};
    $self->logger->info( "STATUS: remaining=$status->{remaining} unstarted=$num_unstarted available=$num_available sourceable=$num_sourceable" );

    if ( $status->{remaining} == 0 ) {
        $self->logger->warn( "Job complete!" );
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
