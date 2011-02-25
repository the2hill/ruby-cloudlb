module CloudLB
  class ConnectionThrottle
  
    attr_reader :min_connections
    attr_reader :max_connections
    attr_reader :max_connection_rate
    attr_reader :rate_interval
    
    # Initializes a new CloudLB::ConnectionThrottle object with the current values. If there is no connection 
    # throttle currently defined, the enabled? method returns false.
    def initialize(load_balancer)
      @connection    = load_balancer.connection
      @load_balancer = load_balancer
      @lbmgmthost   = @connection.lbmgmthost
      @lbmgmtpath   = @connection.lbmgmtpath
      @lbmgmtport   = @connection.lbmgmtport
      @lbmgmtscheme = @connection.lbmgmtscheme
      populate
      return self
    end
  
    def populate
      response = @connection.lbreq("GET",@lbmgmthost,"#{@lbmgmtpath}/loadbalancers/#{CloudLB.escape(@load_balancer.id.to_s)}/connectionthrottle",@lbmgmtport,@lbmgmtscheme)
      CloudLB::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      data = JSON.parse(response.body)['connectionThrottle']
      @enabled = data == {} ? false : true
      return nil unless @enabled
      @min_connections = data["minConnections"]
      @max_connections = data["maxConnections"]
      @max_connection_rate = data["maxConnectionRate"]
      @rate_interval = data["rateInterval"]
      true
    end
    alias :refresh :populate
  
    # Returns true if the connection throttle is defined and has data, returns false if not.
    def enabled?
      @enabled
    end
    
    # Updates (or creates) the connection throttle with the supplied arguments
    # 
    # To create a health monitor for the first time, you must supply all *required* options. However, to modify an 
    # existing monitor, you need only supply the the value that you want to change.
    #
    # Options include:
    #
    #   * :max_connections - Maximum number of connection to allow for a single IP address. *required*
    #   * :min_connections - Allow at least this number of connections per IP address before applying throttling restrictions. *required*
    #   * :max_connection_rate - Maximum number of connections allowed from a single IP address in the defined :rate_interval. *required*
    #   * :rate_interval - Frequency (in seconds) at which the maxConnectionRate is assessed. For example, a :max_connection_rate of 30 
    #                      with a :rate_interval of 60 would allow a maximum of 30 connections per minute for a single IP address. *required*
    def update(options={})
      data = Hash.new
      data['maxConnections'] = options[:max_connections] if options[:max_connections]
      data['minConnections'] = options[:min_connections] if options[:min_connections]
      data['maxConnectionRate'] = options[:max_connection_rate] if options[:max_connection_rate]
      data['rateInterval'] = options[:rate_interval] if options[:rate_interval]
      
      response = @connection.lbreq("PUT",@lbmgmthost,"#{@lbmgmtpath}/loadbalancers/#{CloudLB.escape(@load_balancer.id.to_s)}/connectionthrottle",@lbmgmtport,@lbmgmtscheme,{},data.to_json)
      CloudLB::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      populate
      true
    end
    
    # Convenience method to update the max_connections value. Returns false if the connection throttle is not enabled,
    # the new value if it succeeds, and raises an exception otherwise.
    def max_connections=(value)
      return false unless @enabled
      update(:max_connections => value)
    end
    
    # Convenience method to update the min_connections value. Returns false if the connection throttle is not enabled,
    # the new value if it succeeds, and raises an exception otherwise.
    def min_connections=(value)
      return false unless @enabled
      update(:min_connections => value)
    end
    
    # Convenience method to update the max_connection_rate value. Returns false if the connection throttle is not enabled,
    # the new value if it succeeds, and raises an exception otherwise.
    def max_connection_rate=(value)
      return false unless @enabled
      update(:max_connection_rate => value)
    end
    
    # Convenience method to update the rate_interval value. Returns false if the connection throttle is not enabled,
    # the new value if it succeeds, and raises an exception otherwise.
    def rate_interval=(value)
      return false unless @enabled
      update(:rate_interval => value)
    end
    
    # Removes the current health monitor.  Returns true if successful, exception otherwise.
    #
    #     >> monitor.destroy!
    #     => true
    def destroy!
      response = @connection.lbreq("DELETE",@lbmgmthost,"#{@lbmgmtpath}/loadbalancers/#{CloudLB.escape(@load_balancer.id.to_s)}/connectionthrottle",@lbmgmtport,@lbmgmtscheme)
      CloudLB::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      @enabled = false
      true
    end
  end
end
