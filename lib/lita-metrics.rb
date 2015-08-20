require 'lita'

Lita.load_locales Dir[File.expand_path(
  File.join('..', '..', 'locales', '*.yml'), __FILE__
)]

require 'logger'
require 'statsd'

require 'lita/handlers/metrics'

Lita::Handlers::Metrics.template_root File.expand_path(
  File.join('..', '..', 'templates'),
 __FILE__
)
