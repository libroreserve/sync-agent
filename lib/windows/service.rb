require 'dotenv'
require 'win32/daemon'

require_relative '../agent'

include Win32

Dotenv.load(File.expand_path('../../../CONFIGURATION',  __FILE__))
ENV['HANDLER'] = 'portable'
ENV['API_ENDPOINT'] ||= 'https://api.libroreserve.com/inbound/maitre_d/status'
ENV['STATUS_ENDPOINT'] ||= 'https://api.libroreserve.com/inbound/maitre_d/service'

if [nil, ''].include? ENV['WORKING_DIR']
  ENV['WORKING_DIR'] = `echo %cd%\\working`.chomp
end
Dir.mkdir(ENV['WORKING_DIR']) unless File.directory?(ENV['WORKING_DIR'])
Dir.mkdir('tmp') unless File.directory?('tmp')

LOGGER = Logger.new('tmp/service-log.txt', LOG_COUNT, LOG_LIMIT)

begin
  class WatcherDaemon < Daemon
    def service_init
      LOGGER.info 'Initializing service'
    end

    def service_main
      LOGGER.info 'Service is running'

      @agent = Agent.new(ENV['WORKING_DIR'], /RTBL.+\.xml|ST.+\.xml/i, ENV['API_ENDPOINT'], logger: LOGGER, token: ENV['LIBRO_API_TOKEN'], code: ENV['RESTAURANT_CODE'], strip_invoice_data: ['true', '1'].include?(ENV['STRIP_INVOICE_DATA']))
      @agent.watch!

      hash = `git rev-parse --short HEAD`.chomp rescue nil
      @agent.endpoint.post(ENV['STATUS_ENDPOINT'], { status: 'initialized', version: hash }.to_json) rescue nil

      # keep process in sleep while waiting for new files
      while running?
        if state != SERVICE_PAUSED
          @agent.process!
        end
        sleep 30
      end
    rescue Exception => e
      LOGGER.error "Agent failure; exception: #{e.inspect}\n#{e.backtrace.join($/)}"
      @agent.endpoint.post(ENV['STATUS_ENDPOINT'], { status: 'failed', exception: "#{e.inspect}\n#{e.backtrace.join($/)}" }.to_json) rescue nil

      # upgrade & restart the service
      system 'lib/upgrade.bat'
    end

    def service_stop
      LOGGER.info 'Service stopped'
      @agent.endpoint.post(ENV['STATUS_ENDPOINT'], { status: 'stopped' }.to_json) rescue nil
    end
  end

  WatcherDaemon.mainloop

rescue Exception => e
  LOGGER.error "Daemon failure; exception: #{e.inspect}\n#{e.backtrace.join($/)}"
  raise
end
