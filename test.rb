require 'dotenv'
require 'logger'
require 'pry-byebug'

require './lib/agent'

Dotenv.load(File.expand_path('../.env.test',  __FILE__))
ENV['HANDLER'] = 'portable'
ENV['API_ENDPOINT'] ||= 'http://api.local.libroreserve.com:3000/inbound/maitre_d/status'
ENV['WORKING_DIR'] ||= File.expand_path('working')

class TestDaemon
  def self.mainloop
    agent = Agent.new(ENV['WORKING_DIR'], /RTBL.+\.xml/i, ENV['API_ENDPOINT'], logger: Logger.new(STDOUT), token: ENV['LIBRO_API_TOKEN'], code: ENV['RESTAURANT_CODE'])
    agent.watch!

    # keep process in sleep while waiting for new files
    while true
      agent.process!
      sleep 10
    end
  rescue Interrupt
    # Handle process interruption (CTRL+C)
  end
end

TestDaemon.mainloop