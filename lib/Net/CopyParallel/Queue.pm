package Net::CopyParallel::Queue;
use Moo;
use namespace::clean;

# VERSION

use Log::Log4perl;

has queue => (
    is => 'ro',
    default => sub { return {} },
);

has queue_idx => (
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


sub enqueue {
    my ( $self, $command_obj ) = @_;

    unless ( ref $command_obj eq "Net::CopyParallel::Xfer" ) {
        die "ERROR: attempted to insert something other than a Net::CopyParallel::Xfer object into the queue";
    }

    my $id = $self->queue_idx( $self->queue_idx() + 1 );

    $self->queue->{$id} = $command_obj;

    $self->logger->info( "Added item to queue: id=$id" );

    return $id;
}

sub get_queue_length {
    my ( $self ) = @_;

    return scalar keys %{ $self->queue };
}

sub process {
    my ( $self ) = @_;

    $self->logger->info( "Processing items in queue" );

    unless ( $self->get_queue_length() ) {
        $self->logger->info( "Queue is empty" );
        return;
    }

    for my $idx ( sort { $a <=> $b } keys %{ $self->queue } ) {

        # look for any items which aren't started, and start them
        unless ( $self->queue->{$idx}->started ) {
            $self->queue->{$idx}->start();
            next;
        }

        # look for any processes which have finished
        my $status = $self->queue->{$idx}->check_status();
        if ( $status ) {
            if ( $status->{exit} ) {
                $self->logger->info( "Process failed: $idx" );
            }
            else {
                $self->logger->info( "Process succeeded: $idx" );
            }

            delete $self->queue->{$idx};
        }
        else {
            $self->logger->info( "Process still active: $idx" );
        }
    }

    return 1;
}

1;
