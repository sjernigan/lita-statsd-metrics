# lita-statsd-metrics

[![Build Status](https://img.shields.io/travis/PagerDuty/lita-metrics/master.svg)](https://travis-ci.org/sjernigan/lita-statsd-metrics)
[![MIT License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://tldrlegal.com/license/mit-license)

todo RubyGems :: RMuh Gem Version
todo Coveralls Coverage
todo Code Climate
todo Gemnasium

**lita-statsd-metrics** is a handler for [Lita](https://github.com/jimmycuadra/lita) that keeps track of Lita usage metrics (e.g. users, rooms, handlers and methods triggered) using statsd. It's based on a Datadog specific handler at [lita-metrics](https://github.com/PagerDuty/lita-metrics). The metrics are reported different due to statsd lack of tags.  It also logs messages that match valid chat routes, as well as attempted commands that failed to trigger any handlers.

## Installation

Add lita-metrics to your Lita instance's Gemfile:

``` ruby
gem "lita-statsd-metrics"
```

## Configuration

### Optional attributes
* `statsd_host` - Your Statsd server's address. Default: `'localhost'`
* `statsd_port`- Your Statsd server's port. Default: `8125`
* `valid_command_logger` - [Logger options](http://ruby-doc.org/stdlib-2.2.0/libdoc/logger/rdoc/Logger.html#label-How+to+create+a+logger) for recording messages that match routes. Default: `STDOUT`
* `invalid_command_logger` - Logger options for recording failed commands. Default: `STDOUT`
* `valid_metric_path` - The root of the path.  The following fields will be replaced in the template. Default: `'lita.command.valid.#{handler}.#{method}.#{user}'`
  * `user` - ID of the user who sent the message
  * `room` - ID of the room in which the message was sent
  * `message` - The message text
    * The message can be followed by a regex with capture groups.  The captured groups are joined together with an underscore.  For example `#{message/([\S]*)\s?([\S]*)?/}` will match the command and the first argument if there is one.  
  * `command` - A boolean indicating whether the message was a command
  * `handler` - The name of the handler invoked. Not available for invalid commands
  * `method` - The name of the handler method invoked. Not available for invalid commands
  * `pattern` - The regex pattern matched. Not available for invalid commands
* `invalid_metric_path` - The root of the path.  The same fields as above can be used in the template except as noted. Default: `'lita.command.invalid.#{user}'`
* `log_fields` - Fields to include in the logs; possible options are listed below. Default: `[:user, :room, :message]`
  * `:user` - ID of the user who sent the message
  * `:room` - ID of the room in which the message was sent
  * `:message` - The message text
  * `:command` - A boolean indicating whether the message was a command
  * `:handler` - The name of the handler invoked. Not available for invalid commands
  * `:method` - The name of the handler method invoked. Not available for invalid commands
* `ignored_methods` - An array of methods that should be ignored. Useful for handler methods that "overhear" messages not necessarily directed at the bot. Default: `[]`

``` ruby
Lita.configure do |config|
  config.handlers.metrics.statsd_host = 'localhost'
  config.handlers.metrics.statsd_port = 8125
  config.handlers.metrics.valid_command_logger = '/var/log/lita/messages.log', 'daily'
  config.handlers.metrics.invalid_command_logger = '/var/log/lita/attempted_commands.log', 10, 1024000
  config.handlers.metrics.valid_metric_path = 'lita.command.valid.#{room}.#{handler}'
  config.handlers.metrics.invalid_metric_path = 'lita.command.invalid.#{user}'
  config.handlers.metrics.log_fields = [:user, :handler, :message]
  config.handlers.metrics.ignored_methods = ['Jira#ambient']
end
```

## Usage

Once the handler is configured, it will record metrics and logs without needing to be invoked explicitly by any commands. For example, if I send the command `roll` from user SteveJernigan and [lita-dice](https://github.com/tristaneuan/lita-dice) is installed, the StatsD server will receive these:
```
lita.command.valid.Dice.roll.SteveJernigan:1|c
lita.command.room.devops:1|c
```
...and the log might look like this:
```
I, [2015-08-21T17:45:33.761986 #81678]  INFO -- : 1,shell,roll
```

If I send the command `foo` and there is no handler installed that recognizes it, the StatsD server will receive this:
```
lita.commands.invalid.SteveJernigan:1|c
```
...and the log might look like this:
```
I, [2015-08-24T16:40:25.726132 #45705]  INFO -- : 1,shell,foo
```

## License

[MIT](http://opensource.org/licenses/MIT)
