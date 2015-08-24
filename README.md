# lita-metrics

**lita-metrics** is a handler for [Lita](https://github.com/jimmycuadra/lita) that keeps track of Lita usage metrics (e.g. users, rooms, handlers and methods triggered) using [Datadog](http://www.datadoghq.com/). It also logs messages that match valid chat routes, as well as attempted commands that failed to trigger any handlers.

## Installation

Add lita-metrics to your Lita instance's Gemfile:

``` ruby
gem "lita-metrics"
```

## Configuration

### Optional attributes
* `statsd_host` - Your Statsd server's address. Default: `'localhost'`
* `statsd_port`- Your Statsd server's port. Default: `8125`
* `valid_command_logger` - [Logger options](http://ruby-doc.org/stdlib-2.2.0/libdoc/logger/rdoc/Logger.html#label-How+to+create+a+logger) for recording messages that match routes. Default: `STDOUT`
* `invalid_command_logger` - Logger options for recording failed commands. Default: `STDOUT`
* `valid_command_metric` - The name of the valid message counter to be incremented in Datadog. Default: `'lita.commands.valid'`
* `invalid_command_metric` - The name of the invalid command counter to be incremented in Datadog. Default: `'lita.commands.invalid'`
* `log_fields` - Fields to include in the logs; possible options are listed below. Default: `[:user, :room, :message]`
  * `:user` - ID of the user who sent the message
  * `:room` - ID of the room in which the message was sent
  * `:message` - The message text
  * `:command` - A boolean indicating whether the message was a command
  * `:handler` - The name of the handler invoked. Not available for invalid commands
  * `:method` - The name of the handler method invoked. Not available for invalid commands

``` ruby
Lita.configure do |config|
  config.handlers.metrics.statsd_host = 'localhost'
  config.handlers.metrics.statsd_port = 8125
  config.handlers.metrics.valid_command_logger = '/var/log/lita/messages.log', 'daily'
  config.handlers.metrics.invalid_command_logger = '/var/log/lita/attempted_commands.log', 10, 1024000
  config.handlers.metrics.valid_command_metric = 'lita.messages.all'
  config.handlers.metrics.invalid_command_metric = 'lita.messages.failed'
  config.handlers.metrics.log_fields = [:user, :handler, :message]
end
```

## Usage

Once the handler is configured, it will record metrics and logs without needing to be invoked explicitly by any commands. For example, if I send the command `/r/chatops` and [lita-snoo](https://github.com/tristaneuan/lita-snoo) is installed, the StatsD server will receive this:
```
lita.commands.valid:1|c|#user:1,private_message:false,command:true,room:shell,handler:Lita::Handlers::Snoo,method:subreddit
```
...and the log might look like this:
```
I, [2015-08-21T17:45:33.761986 #81678]  INFO -- : 1,shell,/r/chatops
```

If I send the command `foo` and there is no handler installed that recognizes it, the StatsD server will receive this:
```
lita.commands.invalid:1|c|#user:1,private_message:false,command:true,room:shell
```
...and the log might look like this:
```
I, [2015-08-24T16:40:25.726132 #45705]  INFO -- : 1,shell,foo
```

## License

[MIT](http://opensource.org/licenses/MIT)
