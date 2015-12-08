module Lita
  module Handlers
    class StatsdMetrics < Handler
      class << self
        attr_accessor :statsd
        attr_accessor :valid_command_log
        attr_accessor :invalid_command_log
      end

      config :statsd_host, type: String, default: 'localhost'
      config :statsd_port, type: Integer, default: 8125
      config :valid_command_logger, default: STDOUT
      config :invalid_command_logger, default: STDOUT
      config :command_metric_path, type: String, default: 'lita'
      #config :invalid_command_metric, type: String, default: 'lita.commands.invalid'
      config :log_fields, default: [:user, :room, :message]
      config :ignored_methods, type: Array, default: []

      on :loaded, :setup
      on :message_dispatched, :valid_command
      on :unhandled_message, :invalid_command

      def setup(_payload)
        self.class.statsd = Statsd.new(config.statsd_host, config.statsd_port)
        self.class.valid_command_log = ::Logger.new(*arrayize(config.valid_command_logger))
        self.class.invalid_command_log = ::Logger.new(*arrayize(config.invalid_command_logger))
      end

      def safe(str)
        return str.gsub(" ","_").gsub(".","_")
      end

      def valid_command(payload)
        fields = extract_fields(payload)

        return if ignore?(fields)

        metric_name = "config.command_metric_path.command.valid.#{fields[:Handler].gsub('Lita::Handlers::','')}.#{safe(fields[:method])}.#{safe(fields[:user])}"
        self.class.statsd.increment(metric_name)

        metric_name = "config.command_metric_path.room.#{fields[:Handler].gsub('Lita::Handlers::','')}.#{safe(fields[:method])}"
        self.class.statsd.increment(metric_name)

        self.class.valid_command_log.info(format_log(fields)) unless fields[:private_message]
      end

      def invalid_command(payload)
        fields = extract_fields(payload)

        return unless fields[:command]

        metric_name = "config.command_metric_path.command.invalid.#{safe(fields[:method])}.#{safe(fields[:user])}"
        self.class.statsd.increment(metric_name)

        self.class.invalid_command_log.info(format_log(fields)) unless fields[:private_message]
      end

      private

      def arrayize(arg)
        arg.is_a?(Array) ? arg : [arg]
      end

      # rubocop:disable Metrics/MethodLength
      # Note: This could be refactored into smaller functions at some point
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
      # rubocop:enable Metrics/MethodLength

      def format_log(fields)
        CSV.generate_line(arrayize(config.log_fields).each.map { |x| fields[x] }).chomp
      end

      def ignore?(fields)
        config.ignored_methods.map { |string| string.split('#') }.each do |handler, method|
          return true if same?(fields[:handler], "Lita::Handlers::#{handler}") && same?(fields[:method], method)
        end
        false
      end

      def same?(a, b)
        a.to_s.downcase == b.to_s.downcase
      end
    end

    Lita.register_handler(StatsdMetrics)
  end
end
