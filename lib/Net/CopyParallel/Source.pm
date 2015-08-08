package Net::CopyParallel::Source;

use Moo;
use namespace::clean;

has path => (
    is => 'ro',
    required => 1,
    isa => sub {
        die "ERROR: Path not specified" unless $_[0];
        die "ERROR: Path not found: $_[0]" unless -r $_[0];
    },
);

1;
