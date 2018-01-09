require 'rubygems'
require 'win32/service'

include Win32

SERVICE = 'libro-sync-agent'


# stop and delete the service if it already exists
begin
  Service.stop(SERVICE) if Service.status(SERVICE).controls_accepted.include? "stop"
  sleep 3
rescue
end


# create the new service if it doesn’t exist
Service.create({
  service_name: SERVICE,
  host: nil,
  service_type: Service::WIN32_OWN_PROCESS,
  description: 'Handles POS output files and pushes the data to a Libro Webhook',
  start_type: Service::AUTO_START,
  error_control: Service::ERROR_NORMAL,
  binary_path_name: "#{`where ruby`.chomp} -C #{`echo %cd%`.chomp} lib/windows/service.rb",
  load_order_group: 'Network',
  dependencies: nil,
  display_name: 'Libro Sync'
}) unless Service.exists?(SERVICE)


# start the service
Service.start(SERVICE)
