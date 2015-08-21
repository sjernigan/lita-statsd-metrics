require 'spec_helper'

describe Lita::Handlers::Metrics, lita_handler: true do
  let(:test_handler) do
    Class.new do
      extend Lita::Handler::ChatRouter

      def self.name
        'Test'
      end

      route(/message/, :test_message)
      route(/command/, :test_command, command: true)

      def test_message(response)
        response.reply('message')
      end

      def test_command(response)
        response.reply('command')
      end

      route(/block/) do |response|
        response.reply('block')
      end
    end
  end

  let(:john) do
    Lita::User.create('U1234ABCD', name: 'John', mention_name: 'john')
  end

  let(:general) do
    Lita::Room.create_or_update('C1234567890', name: 'general')
  end

  before do
    robot.trigger(:loaded)
    registry.register_handler(test_handler)
  end

  it { is_expected.to route_event(:message_dispatched).to(:message) }
  it { is_expected.to route_event(:unhandled_message).to(:invalid_command) }

  describe '#message' do
    describe "statsd" do
      it 'increments the message counter for messages that match a route' do
        expect(described_class.statsd).to receive(:increment).with(
          'lita.messages',
          tags: [
            'user:U1234ABCD',
            'private_message:false',
            'command:false',
            'room:C1234567890',
            'handler:Test',
            'method:test_message'
          ]
        )
        send_message('message', as: john, from: general)
      end

      it 'counts blocks correctly' do
        expect(described_class.statsd).to receive(:increment).with(
          'lita.messages',
          tags: [
            'user:U1234ABCD',
            'private_message:false',
            'command:false',
            'room:C1234567890',
            'handler:Test',
            'method:(block)'
          ]
        )
        send_message('block', as: john, from: general)
      end

      it 'allows the metric name to be configured' do
        registry.config.handlers.metrics.message_metric_name = 'lita.commands'
        expect(described_class.statsd).to receive(:increment).with(
          'lita.commands',
          tags: anything
        )
        send_command('command', as: john, from: general)
      end

      it 'does not increment the message counter for messages that do not match a route' do
        expect(described_class.statsd).not_to receive(:increment)
        send_message('command', as: john, from: general)
      end
    end

    describe "message_log" do
      it 'logs messages that match a route' do
        expect(described_class.message_log).to receive(:info).with('U1234ABCD,C1234567890,message')
        send_message('message', as: john, from: general)
      end

      it 'does not log messages that do not match a route' do
        expect(described_class.message_log).not_to receive(:info)
        send_message('command', as: john, from: general)
      end

      it 'does not log private messages' do
        expect(described_class.message_log).not_to receive(:info)
        send_message('message', as: john, privately:true)
      end
    end
  end

  describe '#invalid_command' do
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
  end
end
