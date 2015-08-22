# lita-metrics

**lita-metrics** is a handler for [Lita](https://github.com/jimmycuadra/lita) that keeps track of Lita usage metrics using [Datadog](http://www.datadoghq.com/). Additionally, it logs messages that match active chat routes, as well as attempted commands that failed to trigger a handler.

## Installation

Add lita-metrics to your Lita instance's Gemfile:

``` ruby
gem "lita-metrics"
```

## Configuration

### Optional attributes
* `statsd_host` - Your Statsd server's address. default: `'localhost'`
* `statsd_port`- Your Statsd server's port. default: `8125`
* `message_logger` - [Logger options](http://ruby-doc.org/stdlib-2.2.0/libdoc/logger/rdoc/Logger.html#label-How+to+create+a+logger) for recording messages that match routes. default: `STDOUT`
* `invalid_command_logger` - Logger options for recording failed commands. default: `STDOUT`
* `log_fields` - Fields to include in the logs; possible options are listed below. default: `[:user, :room, :message]`
  * `:user` - ID of the user who sent the message
  * `:room` - ID of the room in which the message was sent
  * `:message` - The message text
  * `:command` - A boolean indicating whether the message was a command
  * `:handler` - The name of the handler invoked. Not available for invalid commands
  * `:method` - The name of the handler method invoked. Not available for invalid commands
* `message_metric_name` - The name of the counter to be incremented in Datadog. default: 'lita.messages'

``` ruby
Lita.configure do |config|
  config.handlers.metrics.statsd_host = 'localhost'
  config.handlers.metrics.statsd_port = 8125
  config.handlers.metrics.message_logger = '/var/log/lita/messages.log', 'daily'
  config.handlers.metrics.invalid_command_logger = '/var/log/lita/attempted_commands.log', 10, 1024000
  config.handlers.metrics.log_fields = [:user, :handler, :message]
  config.handlers.metrics.message_metric_name = 'lita.commands.all'
end
```

## Usage

Once the handler is configured, it will record metrics and logs without requiring any direct commands. For example, if I send the command `/r/chatops` and [lita-snoo](https://github.com/tristaneuan/lita-snoo) is installed, the Datadog Agent will receive this:
```
lita.messages:1|c|#user:1,private_message:false,command:true,room:shell,handler:Lita::Handlers::Snoo,method:subreddit
```
...and the log might look like this:
```
I, [2015-08-21T17:45:33.761986 #81678]  INFO -- : 1,shell,/r/chatops
```

## License

[MIT](http://opensource.org/licenses/MIT)
