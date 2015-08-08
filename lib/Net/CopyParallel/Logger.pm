package Net::CopyParallel::Logger;

use Log::Log4perl qw(:easy);

Log::Log4perl->init(\ <<'EOT');
  log4perl.category = DEBUG, Screen
  log4perl.appender.Screen = \
      Log::Log4perl::Appender::ScreenColoredLevels
  log4perl.appender.Screen.layout = \
      Log::Log4perl::Layout::PatternLayout
  log4perl.appender.Screen.layout.ConversionPattern = \
      %d %F{1}: %m %n
EOT

$main::logger = Log::Log4perl->get_logger;

1;
