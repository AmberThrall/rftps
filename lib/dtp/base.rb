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

    def send_packet(packet)
      return if packet.empty?

      size = packet.length

      @thread = RFTPS.instance.new_thread do
        until packet.empty?
          sent = send_impl(packet)
          break if sent.negative?

          packet = packet[sent..]
          debug_progress_bar(size - packet.length, size)
        end
        close_impl
        @client.message PI::ResponseCodes::FILE_ACTION_SUCCESSFUL, 'Success.' if packet.empty?
      end
    end

    def send_ascii(packet)
      packet = "#{packet}\r\n" unless packet[-1] == "\n"
      send_packet packet.gsub(/(?<=[^\r])\n/, "\r\n") # Replace \n with \r\n
    end

    def send_file(file, start_position = 0)
      return unless File.exist?(file)

      offset = start_position
      size = File.size(file)
      debug_goal_percent = -1

      # Check if we have permission to read.
      can_access = RFTPS.instance.do_as(@client.user, @client.pwd) do
        f = File.open(Utils.global_path_to_local(file, @client.root), 'rb')
        f.read(1)
        f.close
        true
      rescue Errno::EACCES
        @client.message PI::ResponseCodes::FILE_UNAVAILABLE, 'Access denied.'
        false
      end

      return unless can_access == 'true'

      @thread = RFTPS.instance.new_thread do
        f = File.open(file, 'rb')
        f.seek(offset)
        until offset >= size
          data = f.read([Config.data_connections.chunk_size, size - offset].min)

          sent = send_impl(data)
          break if sent <= 0

          offset += sent
          debug_progress_bar(offset, size) if (100 * offset / size.to_f) >= debug_goal_percent
          debug_goal_percent = (10 * offset / size.to_f).to_i * 10 + 10
        end
        f.close
        close_impl
        @client.message PI::ResponseCodes::FILE_ACTION_SUCCESSFUL, 'Success.' if offset >= size
      end
    end

    def recv_file(file, append = false)
      Logging.debug("recv_file -> #{file}")

      # Ensure we have write permission
      can_access = RFTPS.instance.do_as(@client.user, @client.pwd) do
        FileUtils.touch(Utils.global_path_to_local(file, @client.root))
        true
      rescue Errno::EACCES
        @client.message PI::ResponseCodes::FILE_UNAVAILABLE, 'Access denied.'
        false
      end

      return unless can_access == 'true'

      @thread = RFTPS.instance.new_thread do
        good_status = true
        f = File.open(file, append ? 'ab' : 'wb')
        loop do
          data = recv_impl
          if data.is_a?(Integer) && data < 0
            good_status = false
            break
          end

          break if data == 0 || data.empty?

          begin
            f.write(data)
          rescue StandardError => e
            Logging.error "Writing error occured: #{e.message}"
            @client.message PI::ResponseCodes::FILE_ACTION_ABORTED, 'Error occured while writing.'
            good_status = false
            break
          end
        end
        f.close
        close_impl
        @client.message PI::ResponseCodes::FILE_ACTION_SUCCESSFUL, 'Success.' if good_status
      end
    end

    protected

    def send_impl(_packet)
      raise 'Not implemented'
    end

    def recv_impl
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
