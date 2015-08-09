package Net::CopyParallel::Xfer;

use Moo;
use namespace::clean;

use Log::Log4perl;

has source_server => (
    is => 'ro',
    required => 1,
);

has target_server => (
    is => 'ro',
    required => 1,
);

has source => (
    is => 'ro',
    required => 1,
);

has queue_id => (
    is => 'rw',
);

has dryrun => (
    is => 'rw',
);

has command => (
    is => 'rw',
    lazy => 1,
    builder => "_build_command",
);

has started => (
    is => 'rw'
);

has 'logger'  => (
    is => 'ro',
    lazy => 1,
    default => sub {
        return Log::Log4perl::get_logger( __PACKAGE__ );
    },
);

sub start {
    my ( $self ) = @_;

    $self->logger->warn( "Starting transfer from ",
                         $self->source_server->hostname,
                         " to ",
                         $self->target_server->hostname,
                     );

    $self->started( 1 );

    $self->source_server->started_send( $self->target_server );
    $self->target_server->started(1);

    $self->command->start();
}

sub check_status {
    my ( $self ) = @_;

    $self->logger->info( "Checking xfer status" );

    my $results = $self->command->get_results();
    return unless $results;

    if ( exists $results->{exit} ) {
        $results->{source} = $self->source_server->hostname;
        $results->{target} = $self->target_server->hostname;
        $results->{status} = $results->{exit} == 0 ? "OK" : "FAILURE";

        $self->logger->warn( "Transfer $results->{status}: $results->{source} => $results->{target}" );

        $self->logger->info( "xfer completed" );
        $self->source_server->finished_send( $self->target_server );

        if ( $results->{exit} ) {
            $self->logger->info( "Xfer failed, server did not receive" );
            $self->target_server->started(0);
        }
        else {
            $self->target_server->finished_receive;
        }
    }

    return $results;
}

sub _build_command {
    my ( $self ) = @_;

    my $src_hostname = $self->source_server->hostname;
    my $tgt_hostname = $self->target_server->hostname;
    my $path = $self->source->path;

    my $commandline;

    my @base = ( "scp" );
    #my @base = ( "rsync", "-ravu", "-e", "ssh" );

    if ( $src_hostname eq 'localhost' ) {
        if ( $self->dryrun ) {
            $commandline = [ 'ssh', $tgt_hostname, 'hostname' ];
        }
        else {
            $commandline = [ @base, $path, "$tgt_hostname:$path" ];
        }
    }
    else {
        if ( $self->dryrun ) {
            $commandline = [ 'ssh', '-A', '-x', $src_hostname, 'ssh', $tgt_hostname, 'hostname' ];
        }
        else {
            $commandline = ['ssh', '-A', '-x', $src_hostname,
                            @base, $path, "$tgt_hostname:$path"
                        ];
        }
    }

    my $command = Net::CopyParallel::Command->new( { command => $commandline,
                                                     dryrun  => 1,
                                                 } );
    return $command;
}

1;
