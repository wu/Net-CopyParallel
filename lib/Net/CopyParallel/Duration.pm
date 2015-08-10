package Net::CopyParallel::Duration;
use Moo;
use namespace::clean;

# VERSION

sub format {
    my ( $self, $elapsed ) = @_;

    return '0s' unless $elapsed;

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
