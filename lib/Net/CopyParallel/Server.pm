package Net::CopyParallel::Server;
use Moo;
use namespace::clean;

# VERSION

use Net::CopyParallel::Command;

use Log::Log4perl;

has hostname => (
    is => 'ro',
    isa => sub { die "hostname can't be blank" unless length($_[0]); },
    required => 1,
);

has has_source => (
    is => 'rw'
);

has started => (
    is => 'rw'
);

has receiving => (
    is => 'rw'
);

has targets => (
    is => 'ro',
    default => sub { return {} },
);

has transferring_to => (
    is => 'ro',
    default => sub { return {} },
);

has logger  => (
    is => 'ro',
    lazy => 1,
    default => sub {
        return Log::Log4perl::get_logger( __PACKAGE__ );
    },
);

has maxprocs => (
    is => 'ro',
    default => 2,
);

sub is_available {
    my ( $self ) = @_;

    return unless $self->has_source;

    if ( $self->count_active_xfers() < $self->maxprocs ) {
        return 1;
    }

    return;
}

sub count_active_xfers {
    my ( $self ) = @_;

    return scalar keys %{ $self->transferring_to };
}


sub started_send {
    my ( $self, $target_server ) = @_;

    if ( $self->count_active_xfers() > $self->maxprocs ) {
        $self->logger->fatal( "ERROR: trying to start another transfer already at maxprocs" );
    }

    $self->transferring_to->{ $target_server->hostname } = 1;
}

sub finished_send {
    my ( $self, $target_server ) = @_;

    delete $self->transferring_to->{ $target_server->hostname };
}

sub finished_receive {
    my ( $self, $source_server ) = @_;

    $self->has_source(1);
}


1;
