module Lita
  module Handlers
    class Metrics < Handler
      config :statsd_host, type: String, default: 'localhost'
      config :statsd_port, type: Integer, default: 8125
      config :message_log_path, default: STDOUT
      config :message_log_rotation, type: String, default: 'daily'
      config :invalid_command_log_path, default: STDOUT
      config :invalid_command_log_rotation, type: String, default: 'weekly'
      config :message_metric_name, type: String, default: 'lita.messages'

      on :loaded, :setup
      on :message_dispatched, :message
      on :unhandled_message, :invalid_command

      def setup(_payload)
        @@statsd = Statsd.new(config.statsd_host, config.statsd_port)
        @@message_log = ::Logger.new(
          config.message_log_path,
          config.message_log_rotation
        )
        @@invalid_command_log = ::Logger.new(
          config.invalid_command_log_path,
          config.invalid_command_log_rotation
        )
      end

      def message(payload)
        handler = payload[:handler]
        route = payload[:route]
        message = payload[:message]
        robot = payload[:robot]

        @@statsd.increment(
          config.message_metric_name,
          tags: [
            "handler:#{handler.name}",
            "method:#{route.callback.method_name}",
            "user:#{message.user.id}",
            "room:#{message.source.room_object.id}",
            "private_message:#{message.source.private_message?}",
            "command:#{message.command?}",
          ]
        )

        @@message_log.info(message.body) unless message.source.private_message?
      end

      def invalid_command(payload)
        message = payload[:message]
        @@invalid_command_log.info(message.body) if !message.source.private_message? && message.command?
      end
    end

    Lita.register_handler(Metrics)
  end
end
