require 'dotenv'
require 'win32/daemon'

require_relative '../agent'

include Win32

Dotenv.load(File.expand_path('../../CONFIGURATION',  __FILE__))
ENV['HANDLER'] = 'portable'

if [nil, ''].include? ENV['WORKING_DIR']
  ENV['WORKING_DIR'] = `echo %cd%\\working`.chomp
end
Dir.mkdir(ENV['WORKING_DIR']) unless File.directory?(ENV['WORKING_DIR'])
Dir.mkdir('tmp') unless File.directory?('tmp')

LOGGER = Logger.new('tmp/service-log.txt')

begin
  class WatcherDaemon < Daemon
    def service_init
      LOGGER.info 'Initializing service'
    end

    def service_main
      LOGGER.info 'Service is running'

      agent = Agent.new(ENV['WORKING_DIR'], /RTBL.+\.xml/, 'http://inbound.local.libroreserve.com:3000/whatever', logger: LOGGER, token: ENV['LIBRO_API_TOKEN'])
      agent.watch!

      # keep process in sleep while waiting for new files
      while running?
        agent.process!
        sleep 30
      end
    rescue Exception => e
      LOGGER.error "Agent failure; exception: #{e.inspect}\n#{e.backtrace.join($/)}"
    end

    def service_stop
      LOGGER.info 'Service stopped'
    end
  end

  WatcherDaemon.mainloop

rescue Exception => e
  LOGGER.error "Daemon failure; exception: #{e.inspect}\n#{e.backtrace.join($/)}"
  raise
end