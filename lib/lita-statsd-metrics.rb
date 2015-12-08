require 'lita'

Lita.load_locales Dir[File.expand_path(
  File.join('..', '..', 'locales', '*.yml'), __FILE__
)]

require 'csv'
require 'logger'
require 'statsd'

require 'lita/handlers/statsd_metrics'

Lita::Handlers::Metrics.template_root File.expand_path(
  File.join('..', '..', 'templates'),
  __FILE__
)
