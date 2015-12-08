require 'spec_helper'

describe Lita::Handlers::StatsdMetrics, lita_handler: true do
  let(:test_handler) do
    Class.new do
      extend Lita::Handler::ChatRouter

      def self.name
        'Lita::Handlers::Test'
      end

      route(/message/, :test_message)
      route(/command/, :test_command, command: true)
      route(/ignore/, :test_ignore)

      def test_message(_response)
      end

      def test_command(_response)
      end

      def test_ignore(_response)
      end

      route(/block/) do |_response|
      end
    end
  end

  let(:john) { Lita::User.create('U1234ABCD', name: 'John', mention_name: 'john') }

  let(:general) { Lita::Room.create_or_update('C1234567890', name: 'general') }

  before(:each) do
    robot.trigger(:loaded)
    registry.register_handler(test_handler)
  end

  it { is_expected.to route_event(:message_dispatched).to(:valid_command) }
  it { is_expected.to route_event(:unhandled_message).to(:invalid_command) }

  describe '#valid_command' do
    describe 'statsd' do
      it 'increments the valid command counter for messages that match a route' do
        expect(described_class.statsd).to receive(:increment).with(
          'lita.commands.valid',
          tags: [
            'user:U1234ABCD',
            'private_message:false',
            'command:false',
            'room:C1234567890',
            'handler:Lita::Handlers::Test',
            'method:test_message'
          ]
        )
        send_message('message', as: john, from: general)
      end

      it 'counts blocks correctly' do
        expect(described_class.statsd).to receive(:increment).with(
          'lita.commands.valid',
          tags: [
            'user:U1234ABCD',
            'private_message:false',
            'command:false',
            'room:C1234567890',
            'handler:Lita::Handlers::Test',
            'method:(block)'
          ]
        )
        send_message('block', as: john, from: general)
      end

      it 'allows the valid command metric name to be configured' do
        registry.config.handlers.metrics.valid_command_metric = 'lita.messages.all'
        expect(described_class.statsd).to receive(:increment).with(
          'lita.messages.all',
          tags: anything
        )
        send_command('command', as: john, from: general)
      end

      it 'ignores methods specified in the configuration' do
        registry.config.handlers.metrics.ignored_methods = %w(Test#test_ignore)
        expect(described_class.statsd).not_to receive(:increment)
        send_message('ignore')
      end
    end

    describe 'logger' do
      it 'logs messages that match a route' do
        expect(described_class.valid_command_log).to receive(:info).with('U1234ABCD,C1234567890,message')
        send_message('message', as: john, from: general)
      end

      it 'does not log messages that do not match a route' do
        expect(described_class.valid_command_log).not_to receive(:info)
        send_message('foo', as: john, from: general)
      end

      it 'does not log commands that do not match a route' do
        expect(described_class.valid_command_log).not_to receive(:info)
        send_command('foo', as: john, from: general)
      end

      it 'does not log private messages' do
        expect(described_class.valid_command_log).not_to receive(:info)
        send_message('message', as: john, privately: true)
      end
    end
  end

  describe '#invalid_command' do
    describe 'statsd' do
      it 'increments the invalid command counter for commands that do not match a route' do
        expect(described_class.statsd).to receive(:increment).with(
          'lita.commands.invalid',
          tags: [
            'user:U1234ABCD',
            'private_message:false',
            'command:true',
            'room:C1234567890'
          ]
        )
        send_command('foo', as: john, from: general)
      end

      it 'does not increment the invalid command counter for messages that do not match a route' do
        expect(described_class.statsd).not_to receive(:increment).with(
          'lita.commands.invalid',
          tags: anything
        )
        send_message('foo', as: john, from: general)
      end

      it 'allows the invalid command metric name to be configured' do
        registry.config.handlers.metrics.invalid_command_metric = 'lita.messages.failed'
        expect(described_class.statsd).to receive(:increment).with(
          'lita.messages.failed',
          tags: anything
        )
        send_command('foo', as: john, from: general)
      end
    end

    describe 'logger' do
      it 'logs unhandled commands' do
        expect(described_class.invalid_command_log).to receive(:info).with('U1234ABCD,C1234567890,foo')
        send_command('foo', as: john, from: general)
      end

      it 'does not log unhandled messages that are not commands' do
        expect(described_class.invalid_command_log).not_to receive(:info)
        send_message('foo', as: john, from: general)
      end

      it 'does not log unhandled commands sent as private messages' do
        expect(described_class.invalid_command_log).not_to receive(:info)
        send_command('foo', as: john, privately: true)
      end

      it 'allows the log fields to be configured' do
        registry.config.handlers.metrics.log_fields = :message
        expect(described_class.invalid_command_log).to receive(:info).with('foo')
        send_command('foo', as: john, from: general)
      end
    end
  end
end
