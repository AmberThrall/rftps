# frozen_string_literal: true

require_relative '../rftps'

module DTP
  # Base class inherited by Active and Passive
  class Base
    PROGRESS_BAR_OPTIONS = {
      format: 'Sending: $progress/$total bytes $bar $percent%',
      width: 25
    }.freeze

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

      size = packet.length

      @thread = RFTPS.instance.new_thread do
        until packet.empty?
          sent = send_impl(packet)
          break if sent <= 0

          packet = packet[sent..]
          debug_progress_bar(size - packet.length, size)
        end
        close_impl
        @client.message PI::ResponseCodes::FILE_ACTION_SUCCESSFUL, 'Success.' if packet.empty?
      end
    end

    def send_ascii(packet)
      packet = "#{packet}\r\n" unless packet[-1] == "\n"
      send packet.gsub(/(?<=[^\r])\r/, "\r\n") # Replace \n with \r\n
    end

    protected

    def send_impl(_packet)
      raise 'Not implemented'
    end

    def close_impl
      raise 'Not implemented'
    end

    private

    def debug_progress_bar(progress, total)
      Logging.debug Utils.progress_bar(progress, total, **PROGRESS_BAR_OPTIONS)
    end
  end
end
