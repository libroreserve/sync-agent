require 'listen'
require 'faraday'
require 'nokogiri'
require 'active_support/core_ext/hash/conversions'
require 'json'

class Agent
  @@processing = []

  def initialize(directory, pattern, endpoint, options={})
    @directory = directory
    @pattern = pattern

    @logger = options[:logger] || Logger.new('tmp/processing-log.txt')

    ssl = if options[:ssl_cert_path]
      { ssl: { ca_file: options[:ssl_cert_path] }}
    else
      { ssl: { verify: false }}
    end

    @endpoint = Faraday.new({ url: endpoint }.merge(ssl)) do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP

      faraday.use Faraday::Response::RaiseError # raise http errors
    end

    # @endpoint.authorization(:Token, 'Auth-Token': options[:token], 'Restaurant-Code': options[:code])
    @endpoint.headers['Authorization'] = "Token Auth-Token=\"#{options[:token]}\", Restaurant-Code=\"#{options[:code]}\""

    @logger.info("Agent initialized; directory: #{directory}; pattern: #{pattern}; endpoint: #{endpoint}; options: #{options};")
  end

  def watch!
    # listen for new files
    listener = Listen.to(@directory) do |modified, added, removed|
      files = added + modified
      unless files.empty?
        files.each do |file_path|
          unless file_path !~ @pattern
            process(file_path)
          end
        end
      end
    end

    listener.start
  end

  def process!
    # deal with files currently in  working directory
    Dir.entries(@directory).reject{|f| File.directory?(f)}
                           .map{|f| File.join(@directory, f)}
                           .each do |file_path|
      unless file_path !~ @pattern
        process(file_path)
      end
    end
  end

  private
    def process(file_path)
      if @@processing.include?(file_path)
        # file is already in process; abort
        # this senario happens because of a race between the timed loop and listener
        return
      end

      @@processing << file_path

      @logger.info("File processing: #{file_path}")
      push(parse(file_path))

      File.delete(file_path) if File.exists?(file_path)
      @logger.info("File deleted: #{file_path}")

    rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Net::ReadTimeout => e
      @logger.error("Could not connect to Libro server: #{e.message}")
    rescue Faraday::ResourceNotFound => e
      @logger.error("Specified endpoint was not found on Libro server")
    rescue Faraday::ClientError => e
      @logger.error("Client error: #{e.message}")
    # rescue Exception => e
    #   @logger.error("Error parsing file: #{file_path}")
    ensure
      @@processing.delete(file_path)
    end

    def parse(file_path)
      doc = File.open(file_path) {|f| Nokogiri::XML(f) }
      Hash.from_xml(doc.to_xml)
    end

    def push(data)
      # push data to endpoint

      response = @endpoint.post do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = data.to_json
      end
    end

end