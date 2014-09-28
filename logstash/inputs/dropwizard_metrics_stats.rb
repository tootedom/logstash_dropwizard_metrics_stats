# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "logstash/util/socket_peer"


# Read memcached_stats over a TCP socket.
#
# Like stdin and file inputs, each event is assumed to be one line of text.
#
class LogStash::Inputs::DropwizardMetricsStats < LogStash::Inputs::Base
  class Interrupted < StandardError; end
  config_name "dropwizard_metrics_stats"
  milestone 1

  default :http, nil

  default :codec, "line"

  # Enable the plugin or not
  config :enabled, :validate => :boolean, :default => true

  # The url for the admin end point to query for metrics
  config :url, :validate => :string, :default => "http://localhost:8081/metrics"

  # The timeout for the connection to the admin endpoint, in seconds
  config :connect_timeout_s, :validate => :number, :default => 1

  # The timeout for the request to the admin endpoint to obtain metrics, in seconds
  config :request_timeout_s, :validate => :number, :default => 1

  # The polling period for talking to dropwizard admin interface to obtain metrics command, default 1
  config :poll_period_s, :validate => :number, :default => 1

  # The time (seconds) to wait before attempting to connect to dropwizard app again, default 5
  config :reconnect_period_s, :validate => :number, :default => 5

  # Stats separator.  This is the separate used to separate the different stats.  default is a pipe character
  config :stat_separator, :validate => :string, :default => "|"

  # The separator used between the key and the value
  config :value_separator, :validate => :string, :default => "="

  # store all as events.  The default is false.  When true all the dropwizard metrics stats will be stored as events
  config :store_all_keys, :validate => :boolean, :default => false

  # regexp string for keys to include
  config :regexp_include_keys, :validate => :array, :default => [ "^gaugesjvmmemory.*$", "^gaugesjvmgc.*$", "^gaugejvmthreads.*$" ]

  # regexp keys to not store
  config :regexp_exclude_keys, :validate => :array, :default => []



  def initialize(*args)
    super(*args)
  end # def initialize

  public
  def register
    # not available in logstash 1.3.3
    #fix_streaming_codecs
    require "socket"
    require "timeout"
    require "net/http"
    require "uri"
  end # def register

  private
  def handle_request(uri, http, output_queue, codec)
    while true
      stats = { }
      response = http.request(Net::HTTP::Get.new(uri.request_uri))
      statsMap = JSON.parse(response.body)

      parseStats(stats, statsMap, "meters")
      parseStats(stats, statsMap, "gauges")
      parseStats(stats, statsMap, "counters")
      parseStats(stats, statsMap, "histograms")
      parseStats(stats, statsMap, "timers")

      if stats.size == 0
        sleep(@poll_period_s)
        next
      end

      line = statsToMessageLine(stats)
      hostname = Socket.gethostname

      codec.decode(line) do |event|
        if(@store_all_keys)
          stats.sort.map { |k,v|
            event[k] ||= v.to_f
          }
        end
        event["host"] = hostname if !event.include?("host")
        event["type"] = "metricstats" if !event.include?("type") || event["type"] =~ /^\s*$/
        event["metricshost"] ||= uri.host
        event["metricsport"] ||= uri.port
        decorate(event)
        output_queue << event
      end

      sleep(@poll_period_s)
    end # loop do
  rescue LogStash::ShutdownSignal => e
    raise e
  rescue EOFError
    @logger.warn("Connection Reset before all data recieved.  Closing connection before retry")
    raise e
  rescue Errno::ECONNREFUSED,Errno::ECONNABORTED, Errno::ECONNRESET, Timeout::Error, Errno::EINVAL, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
    @logger.warn("An error occurred whilst performing metrics http request. Closing connection before retry.", :exception => e,:backtrace => e.backtrace)
    raise e
  rescue => e
    @logger.warn("An unexpected error occurred during metrics http request. Closing connection before retry",
                  :exception => e, :backtrace => e.backtrace)
    raise e
  ensure
    hostname = Socket.gethostname
    codec.respond_to?(:flush) && codec.flush do |event|
      event["host"] = hostname if !event.include?("host")
      event["type"] = "metricstats" if !event.include?("type") || event["type"] =~ /^\s*$/
      event["metricshost"] ||= uri.host
      event["metricsport"] ||= uri.port
      decorate(event)
      output_queue << event
    end
  end

  private
  def parseStats(stats, statsMap, metricType)
    map = statsMap[metricType]
    map.each_key do |key|
      map[key].each do | metricName, metricValue |
        if metricValue.respond_to?(:to_i)
          metricKey = metricType + key + metricName
          metricKey = metricKey.downcase
          metricKey.gsub!(/\./,'')
          metricKey.gsub!(/-/,'')
          include = false
          exclude = false

          if @regexp_includes.length > 0
            @regexp_includes.each { |regex|
              if metricKey =~ /#{regex}/
                include = true
                break
              end
            }
          else
            include = true
          end

          if @regexp_excludes.length > 0
            @regexp_excludes.each { |regex|
              if metricKey =~ /#{regex}/
                exclude = true
                break
              end
            }
          else
            exclude = false
          end


          if include and !exclude
            stats[metricKey] = metricValue
          end

        end
      end
    end
  end

  private
  def statsToMessageLine(stats)
    line = ""
    stats.sort.map {|k,v| line = line + @stat_separator + k.to_s + @value_separator + v.to_s  }
    return line + "|\n"
  end


  public
  def run(output_queue)
      run_client(output_queue) 
  end # def run


  def run_client(output_queue) 
    @thread = Thread.current
    @logger.debug("starting dropwizard metrics")

    if @enabled == false
      return
    end
    notfinished = true

    uri = URI(@url)

    @regexp_includes = Array.new
    @regexp_excludes = Array.new

    @regexp_exclude_keys.each { |key| @regexp_excludes << Regexp.new(/#{key}/) }
    @regexp_include_keys.each { |key| @regexp_includes << Regexp.new(/#{key}/) }


    while notfinished
      begin
        @http = Net::HTTP.new(uri.host, uri.port)
        @http.open_timeout = @connect_timeout_s # in seconds
        @http.read_timeout = @request_timeout_s # in seconds
        handle_request(uri, @http, output_queue, @codec.clone)
      rescue LogStash::ShutdownSignal
        notfinished = false
        closeHttp()
      rescue Exception => e
        closeHttp()
        case e
          when Errno::ECONNREFUSED,Errno::ECONNABORTED,Errno::ECONNRESET,
              EOFError, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
              Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError
            @logger.warn("Failed to get metrics from app #{uri.request_uri}, retrying connection in #{@reconnect_period_s} seconds", :name => @host,
                       :exception => e, :backtrace => e.backtrace)
            sleep(@reconnect_period_s)
          else
            raise e
        end
      end
    end # loop
  ensure
    if @http
      closeHttp
    end
  end # def run

  private
  def closeHttp()
    begin
      @http.finish
    rescue IOError
      nil
    end
  end

  public
  def teardown    
  end # def teardown
end # class LogStash::Inputs::DropwizardMetricsStats

