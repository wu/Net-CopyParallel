package Net::CopyParallel::Logger;
use Moo;
use namespace::clean;

# VERSION

use Log::Log4perl qw(:easy);

sub init {
    my ( $self, $level ) = @_;

    unless ( $level ) {
        for my $lvl ( qw( trace debug info warn error fatal off ) ) {
            my $env_var = join( "_", 'LOG', uc($lvl) );
            if ( $ENV{$env_var} ) {
                $level = uc( $lvl );
            }
        }
    }
    unless ( $level ) {
        if ( $0 =~ m|\.t$| ) {
            $level = 'OFF';
        }
    }
    unless ( $level ) {
        $level = 'WARN';
    }

    my $conversion_pattern = '%d: %m %n';
    if ( $level =~ m/INFO|DEBUG|TRACE/ ) {
        $conversion_pattern = '%d %F{1}: %m %n';;
    }

    Log::Log4perl->init(\ <<"EOT");
  log4perl.category                                 = $level, Screen
  log4perl.appender.Screen                          = Log::Log4perl::Appender::ScreenColoredLevels
  log4perl.appender.Screen.layout                   = Log::Log4perl::Layout::PatternLayout
  log4perl.appender.Screen.layout.ConversionPattern = $conversion_pattern
EOT

    $main::logger = Log::Log4perl->get_logger;
}

1;
