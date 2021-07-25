# frozen_string_literal: true

require_relative '../rftps'

module DTP
  # Base class inherited by Active and Passive
  class Base
    def initialize(client)
      @client = client
      @thread = nil
    end

    def connected?
      raise 'Not implemented'
    end

    def close
      close_impl
      @thread&.join
    end

    def abort
      @thread&.exit
      close
    end

    def send(packet)
      return if packet.empty?

      @thread = RFTPS.instance.new_thread do
        until packet.empty?
          sent = send_impl(packet)
          break if sent <= 0

          packet = packet[sent..]
        end
        close_impl
      end
    end

    protected

    def send_impl(_packet)
      raise 'Not implemented'
    end

    def close_impl
      raise 'Not implemented'
    end
  end
end
