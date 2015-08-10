package Net::CopyParallel::EventLog;
use Moo;
use namespace::clean;

# VERSION

use Log::Log4perl;

has history => (
    is => 'ro',
    default => sub { return [] },
);


sub log_event {
    my ( $self, $event_h ) = @_;

    push @{ $self->history }, $event_h;
}

sub display_history {
    my ( $self ) = @_;

    my @return;

    my @keys = qw(date elapsed status source target);

    #push @return, join( ", ", @keys );

    for my $event ( @{ $self->history } ) {

        my @attributes;
        for my $key ( @keys ) {
            push @attributes, $event->{$key} || '';
        }

        push @return, join( ", ", @attributes );
    }

    return @return;
}

1;
