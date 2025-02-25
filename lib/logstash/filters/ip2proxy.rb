# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

require "logstash-filter-ip2proxy_jars"

class LogStash::Filters::IP2Proxy < LogStash::Filters::Base
  config_name "ip2proxy"

  # The path to the IP2Proxy.BIN database file which Logstash should use.
  # If not specified, this will default to the IP2PROXY-LITE-PX1.BIN database that embedded in the plugin.
  config :database, :validate => :path

  # The field containing the IP address.
  # If this field is an array, only the first value will be used.
  config :source, :validate => :string, :required => true

  # The field used to define iplocation as target.
  config :target, :validate => :string, :default => 'ip2proxy'

  # The field used to allow user to enable the use of cache.
  config :use_cache, :validate => :boolean, :default => true

  # The field used to allow user to enable the use of memory mapped file.
  config :use_memory_mapped, :validate => :boolean, :default => false

  # The field used to allow user to hide unsupported fields.
  config :hide_unsupported_fields, :validate => :boolean, :default => false

  # The field used to define lookup type.
  config :lookup_type, :validate => :string, :default => 'db'

  # The field used to define the apikey of IP2location.io.
  config :api_key, :validate => :string, :default => ''

  # The field used to define the size of the cache. It is not required and the default value is 10 000 
  config :cache_size, :validate => :number, :required => false, :default => 10_000

  public
  def register
    if @lookup_type == "ws"
      @logger.info("Using IP2Location.io API")
      if @api_key == ""
        raise "An IP2Location.io API key is required. You may sign up for a free API key at https://www.ip2location.io/pricing."
      end
    else
      if @database.nil?
        @database = ::Dir.glob(::File.join(::File.expand_path("../../../vendor/", ::File.dirname(__FILE__)),"IP2PROXY-LITE-PX1.BIN")).first
  
        if @database.nil? || !File.exists?(@database)
          raise "You must specify 'database => ...' in your ip2proxy filter (I looked for '#{@database}')"
        end
      end
      @logger.info("Using ip2proxy database", :path => @database)
    end

    @ip2proxyfilter = org.logstash.filters.IP2ProxyFilter.new(@source, @target, @database, @use_memory_mapped, @hide_unsupported_fields, @lookup_type, @api_key)
  end

  public
  def filter(event)
    ip = event.get(@source)

    return unless filter?(event)
    if @lookup_type == "ws"
      if @ip2proxyfilter.handleEvent(event)
        filter_matched(event)
      else
        tag_iplookup_unsuccessful(event)
      end
    else
      if @use_cache
        if value = IP2ProxyCache.find(event, ip, @ip2proxyfilter, @cache_size).get('ip2proxy')
          event.set('ip2proxy', value)
          filter_matched(event)
        else
          tag_iplookup_unsuccessful(event)
        end
      else
        if @ip2proxyfilter.handleEvent(event)
          filter_matched(event)
        else
          tag_iplookup_unsuccessful(event)
        end
      end
    end
  end

  def tag_iplookup_unsuccessful(event)
    @logger.debug? && @logger.debug("IP #{event.get(@source)} was not found in the database", :event => event)
  end

end # class LogStash::Filters::IP2Proxy

class IP2ProxyOrderedHash
  ONE = 1

  attr_reader :times_queried # ip -> times queried
  attr_reader :hash

  def initialize
    @times_queried = Hash.new(0) # ip -> times queried
    @hash = {} # number of hits -> array of ips
  end

  def add(key)
    hash[ONE] ||= []
    hash[ONE] << key
    times_queried[key] = ONE
  end

  def reorder(key)
    number_of_queries = times_queried[key]

    hash[number_of_queries].delete(key)
    hash.delete(number_of_queries) if hash[number_of_queries].empty?

    hash[number_of_queries + 1] ||= []
    hash[number_of_queries + 1] << key
  end

  def increment(key)
    add(key) unless times_queried.has_key?(key)
    reorder(key)
    times_queried[key] += 1
  end

  def delete_least_used
    first_pile_with_something.shift.tap { |key| times_queried.delete(key) }
  end

  def first_pile_with_something
    hash[hash.keys.min]
  end
end

class IP2ProxyCache
  ONE_DAY_IN_SECONDS = 86_400

  @cache         = {}            # ip -> event
  @timestamps    = {}            # ip -> time of caching
  @times_queried = IP2ProxyOrderedHash.new # ip -> times queried
  @mutex         = Mutex.new

  class << self
    attr_reader :cache
    attr_reader :timestamps
    attr_reader :times_queried

    def find(event, ip, filter, cache_size)
      synchronize do
        if cache.has_key?(ip)
          refresh_event(event, ip, filter) if too_old?(ip)
        else
          if cache_full?(cache_size)
            make_room
          end
          cache_event(event, ip, filter)
        end
        times_queried.increment(ip)
        cache[ip]
      end
    end

    def too_old?(ip)
      timestamps[ip] < Time.now - ONE_DAY_IN_SECONDS
    end

    def make_room
      key = times_queried.delete_least_used
      cache.delete(key)
      timestamps.delete(key)
    end

    def cache_full?(cache_size)
      cache.size >= cache_size
    end

    def cache_event(event, ip, filter)
      filter.handleEvent(event)
      cache[ip] = event
      timestamps[ip] = Time.now
    end

    def synchronize(&block)
      @mutex.synchronize(&block)
    end

    alias_method :refresh_event, :cache_event
  end
end
