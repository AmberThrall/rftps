# frozen_string_literal: true

require 'optparse'
require 'pathname'
require 'fileutils'
require 'singleton'
require 'socket'

# Main singleton class handling sockets and threads
class RFTPS
  include Singleton

  SELECT_TIMEOUT = 1

  def self.version
    '0.2'
  end

  def initialize
    @sockets = {}
    @threads = []
    @piserver = PI::Server.new
  end

  def register_socket(socket, owner, method)
    @sockets[socket] = { owner: owner, method: method }
  end

  def register_thread(thr)
    @threads.push(thr)
  end

  def unregister_socket(socket)
    @sockets.delete(socket)
    true
  end

  def unregister_thread(thr)
    @threads.delete(thr)
  end

  def thread_count
    remove_dead_threads
    @threads.length
  end

  def new_thread(dont_wait: false, &block)
    wait_for_available_thread unless dont_wait
    thr = Thread.new(&block)
    register_thread thr
    thr
  end

  def start
    @piserver.listen(Config.server.port, Config.server.host)
  end

  def stop
    @piserver.close
  end

  def main_loop
    raise StandardError, 'Please run start before main_loop.' unless @piserver.listening?

    begin
      tick while @piserver.listening?
    rescue SignalException
      stop
    rescue StandardError => e
      stop
      Logging.fatal "Exception: #{e.message}\n  " + e.backtrace.join("\n  ")
    end
  end

  private

  def tick
    remove_dead_threads
    unregister_disconnected
    wait_on_sockets
  end

  def wait_for_available_thread
    return if Config.server.max_threads <= 0

    seconds = 0
    until thread_count < Config.server.max_threads
      sleep(1)
      seconds += 1
    end
    Logging.warning "Waited #{seconds} seconds for an available thread." if seconds.positive?
  end

  def remove_dead_threads
    @threads.filter { |thr| thr.nil? || !thr.alive? }.each { |thr| unregister_thread thr }
  end

  def unregister_disconnected
    @sockets.keys.filter { |sock| sock.nil? || sock.closed? }.each { |sock| unregister_socket sock }
  end

  def wait_on_sockets
    readables, = IO.select(@sockets.keys, [], [], SELECT_TIMEOUT)
    return if readables.nil?

    readables.each do |sock|
      @sockets[sock][:owner].send(@sockets[sock][:method]) if @sockets.key?(sock)
    end
  end
end

# Require everything

Dir[File.join(__dir__, '*.rb')].reject { |f| f[__FILE__] }.sort.each { |file| require file }
