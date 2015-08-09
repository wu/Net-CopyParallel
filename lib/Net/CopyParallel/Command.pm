package Net::CopyParallel::Command;

use Moo;
use namespace::clean;

use Carp;
use File::Temp qw/ :POSIX /;
use Log::Log4perl;
use POSIX ":sys_wait_h";
use System::Command;


has command => (
    is => 'ro',
    required => 1,
    isa => sub {
        confess "command must be an array reference" unless ref $_[0] eq 'ARRAY';
    },
);

has system_command => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        return System::Command->new( @{ $self->command } );
    }
);

has pid => (
    is => 'rw',
);

has failures => (
    is => 'rw',
    default => 0,
);

has tempfile => (
    is => 'ro',
    default => sub {
        my ($fh, $file) = tmpnam();
        close $fh;
        return $file;
    },
);

has results => (
    is => 'rw',
);

has 'logger'  => (
    is => 'ro',
    lazy => 1,
    default => sub {
        return Log::Log4perl::get_logger( __PACKAGE__ );
    },
);

has starttime => (
    is => 'rw',
);

has endtime => (
    is => 'rw',
);

sub start {
    my ( $self ) = @_;

    $self->logger->info( "Starting command: ",
                         join( " ", @{$self->command} )
                     );

    # record start time
    $self->starttime( time );

    $self->pid( $self->system_command->pid() );
}

sub is_started {
    my ( $self ) = @_;

    # if the pid has been set, then the command has been forked
    if ( $self->pid ) {
        return 1;
    }

    return 0;
}

sub is_finished {
    my ( $self ) = @_;

    return unless $self->is_started;

    if ( $self->results ) {
        return 1;
    }

    $self->logger->info( "Started, checking for results..." );
    if ( $self->get_results ) {
        $self->logger->info( "Got results" );
        return 1;
    }

    return;
}

sub get_results {
    my ( $self ) = @_;

    if ( $self->results ) {
        return $self->results;
    }

    my $pid = $self->pid;

    unless ( $self->system_command->is_terminated() ) {
        $self->logger->info( "Command is still active: $pid" );
        return;
    }

    # record end time
    $self->endtime( time );

    $self->logger->info( "Checking command results [$pid]" );

    my @output;
    for my $fh ( $self->system_command->stdout, $self->system_command->stderr ) {
        while ( my $line = <$fh> ) {
            chomp $line;
            push @output, $line;
        }
        close $fh or $self->logger->logdie("Error closing file: $!");
    }

    close $self->system_command->stdin();

    my $runtime = $self->get_runtime_string();

    $self->results( { pid     => $self->system_command->pid(),
                      signal  => $self->system_command->signal(),
                      exit    => $self->system_command->exit(),
                      core    => $self->system_command->core(),
                      command => $self->command,
                      runtime => $runtime,
                      output  => \@output,
                  } );

    $self->logger->info( "Command completed in $runtime ",  );

    return $self->results;

}

sub get_runtime_string {
    my ( $self ) = @_;

    # if the command hasn't finished, how long has it been running so far
    my $end = $self->endtime || time;

    my $elapsed = $end - $self->starttime;

    my @return_string;

    # calculate seconds, minutes, and hours
    my $seconds = $elapsed % 60;
    $elapsed -= $seconds;
    my $minutes = ($elapsed % 3600) / 60;
    $elapsed -= ( $minutes * 60 );
    my $hours = $elapsed / 3600;

    if ( $hours   ) { push @return_string, "${hours}h"   }
    if ( $minutes ) { push @return_string, "${minutes}m" }
    if ( $seconds || ! scalar @return_string ) {
        push @return_string, "${seconds}s";
    }

    return join( " ", @return_string );
}

1;
