package Net::CopyParallel::Logger;

use Moo;
use namespace::clean;

use Log::Log4perl qw(:easy);

sub init {
    my ( $self, $level ) = @_;

    Log::Log4perl->init(\ <<"EOT");
  log4perl.category                                 = $level, Screen
  log4perl.appender.Screen                          = Log::Log4perl::Appender::ScreenColoredLevels
  log4perl.appender.Screen.layout                   = Log::Log4perl::Layout::PatternLayout
  log4perl.appender.Screen.layout.ConversionPattern = %d %F{1}: %m %n
EOT

    $main::logger = Log::Log4perl->get_logger;
}

1;
