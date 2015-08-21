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
        fields = extract_fields(payload)

        @@statsd.increment(
          config.message_metric_name,
          tags: fields.each.map { |k, v| "#{k}:#{v}" }
        )

        @@message_log.info(format_log(fields)) unless fields[:private_message?]
      end

      def invalid_command(payload)
        fields = extract_fields(payload)
        @@invalid_command_log.info(format_log(fields)) if !fields[:private_message?] && fields[:command?]
      end

      private

      def extract_fields(payload)
        m = payload[:message]

        fields = {
          message: m.body,
          user: m.user.id,
          room: m.source.room_object.id,
          private_message?: m.source.private_message?,
          command?: m.command?
        }

        h = payload[:handler]
        r = payload[:route]

        return fields if h.nil? && r.nil?

        fields[:handler] = h.name
        fields[:method] = r.callback.method_name

        fields
      end

      def format_log(fields)
        CSV.generate_line([fields[:user], fields[:room], fields[:message]]).chomp
      end
    end

    Lita.register_handler(Metrics)
  end
end
