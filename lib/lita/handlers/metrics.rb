module Lita
  module Handlers
    class Metrics < Handler
      class << self
        attr_accessor :statsd
        attr_accessor :message_log
        attr_accessor :invalid_command_log
      end

      config :statsd_host, type: String, default: 'localhost'
      config :statsd_port, type: Integer, default: 8125
      config :message_logger, default: STDOUT
      config :invalid_command_logger, default: STDOUT
      config :log_fields, default: [:user, :room, :message]
      config :message_metric_name, type: String, default: 'lita.messages'

      on :loaded, :setup
      on :message_dispatched, :message
      on :unhandled_message, :invalid_command

      def setup(_payload)
        self.class.statsd = Statsd.new(config.statsd_host, config.statsd_port)
        self.class.message_log = ::Logger.new(*arrayize(config.message_logger))
        self.class.invalid_command_log = ::Logger.new(*arrayize(config.invalid_command_logger))
      end

      def message(payload)
        fields = extract_fields(payload)

        self.class.statsd.increment(
          config.message_metric_name,
          tags: fields.each.select { |k, v| k != :message }.map { |k, v| "#{k}:#{v}" }
        )

        self.class.message_log.info(format_log(fields)) unless fields[:private_message]
      end

      def invalid_command(payload)
        fields = extract_fields(payload)
        self.class.invalid_command_log.info(format_log(fields)) if !fields[:private_message] && fields[:command]
      end

      private

      def arrayize(arg)
        arg.is_a?(Array) ? arg : [arg]
      end

      def extract_fields(payload)
        m = payload[:message]

        fields = {
          message: m.body,
          user: m.user.id,
          private_message: m.source.private_message?,
          command: m.command?
        }

        fields[:room] = m.source.room_object.id unless fields[:private_message]

        h = payload[:handler]
        r = payload[:route]

        return fields if h.nil? && r.nil?

        fields[:handler] = h.name
        fields[:method] = r.callback.method_name || '(block)'

        fields
      end

      def format_log(fields)
        CSV.generate_line(arrayize(config.log_fields).each.map { |x| fields[x] }).chomp
      end
    end

    Lita.register_handler(Metrics)
  end
end
