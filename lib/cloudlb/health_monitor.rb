module CloudLB
  class HealthMonitor
  
    attr_reader :type
    attr_reader :delay
    attr_reader :timeout
    attr_reader :attempts_before_deactivation
    attr_reader :path
    attr_reader :status_regex
    attr_reader :body_regex
    
    # Initializes a new CloudLB::ConnectionThrottle object
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
      response = @connection.lbreq("GET",@lbmgmthost,"#{@lbmgmtpath}/loadbalancers/#{CloudLB.escape(@load_balancer.id.to_s)}/healthmonitor",@lbmgmtport,@lbmgmtscheme)
      CloudLB::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      data = JSON.parse(response.body)['healthMonitor']
      @enabled = data == {} ? false : true
      return nil unless @enabled
      @type = data["type"]
      @delay = data["delay"]
      @timeout = data["timeout"]
      @attempts_before_deactivation = data["attemptsBeforeDeactivation"]
      @path = data["path"]
      @status_regex = data["statusRegex"]
      @body_regex = data["bodyRegex"]
      true
    end
    alias :refresh :populate
  
    # Returns true if the health monitor is defined and has data, returns false if not.
    def enabled?
      @enabled
    end
    
    # Updates (or creates) the health monitor with the supplied arguments
    # 
    # To create a health monitor for the first time, you must supply all *required* options. However, to modify an 
    # existing monitor, you need only supply the :type and whatever it is that you want to change.
    #
    # Options include:
    #
    #   * :type - The type of health monitor. Can be CONNECT (simple TCP connections), HTTP, or HTTPS. The HTTP and HTTPS
    #             monitors require additional options. *required*
    #   * :delay - The minimum number of seconds to wait before executing the health monitor. *required*
    #   * :timeout - Maximum number of seconds to wait for a connection to be established before timing out. *required*
    #   * :attempts_before_deactivation - Number of permissible monitor failures before removing a node from rotation. *required*
    #
    # For HTTP and HTTPS monitors, there are additional options. You must supply the :path and either the :status_regex or :body_regex
    #
    #   * :path - The HTTP path that will be used in the sample request. *required*
    #   * :status_regex - A regular expression that will be used to evaluate the HTTP status code returned in the response 
    #   * :body_regex - A regular expression that will be used to evaluate the contents of the body of the response.
    def update(options={})
      data = Hash.new
      data[:type] = options[:type].upcase if options[:type]
      data[:delay] = options[:delay] if options[:delay]
      data[:timeout] = options[:timeout] if options[:timeout]
      data['attemptsBeforeDeactivation'] = options[:attempts_before_deactivation] if options[:attempts_before_deactivation]
      data[:type].upcase! if data[:type]
      if ['HTTP','HTTPS'].include?(data[:type])
        data[:path] = options[:path] if options[:path]
        data['statusRegex'] = options[:status_regex] if options[:status_regex]
        data['bodyRegex'] = options[:body_regex] if options[:body_regex]
      end
      response = @connection.lbreq("PUT",@lbmgmthost,"#{@lbmgmtpath}/loadbalancers/#{CloudLB.escape(@load_balancer.id.to_s)}/healthmonitor",@lbmgmtport,@lbmgmtscheme,{},data.to_json)
      CloudLB::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      populate
      true
    end
    
    # Convenience method to update the delay value for the current type. Returns false if the health monitor is not enabled,
    # the new value if it succeeds, and raises an exception otherwise.
    def delay=(value)
      return false unless @enabled
      update(:type => self.type, :delay => value)
    end
    
    # Convenience method to update the timeout value for the current type. Returns false if the health monitor is not enabled,
    # the new value if it succeeds, and raises an exception otherwise.
    def timeout=(value)
      return false unless @enabled
      update(:type => self.type, :timeout => value)
    end
    
    # Convenience method to update the attempts before deactivation value for the current type. Returns false if the health monitor is not enabled,
    # the new value if it succeeds, and raises an exception otherwise.
    def attempts_before_deactivation=(value)
      return false unless @enabled
      update(:type => self.type, :attempts_before_deactivation => value)
    end
    
    # Convenience method to update the path value for the current type. Returns false if the health monitor is not enabled
    # or not an http monitor, the new value if it succeeds, and raises an exception otherwise.
    def path=(value)
      return false unless @enabled && ['HTTP','HTTPS'].include?(self.type)
      update(:type => self.type, :path => value)
    end
    
    # Convenience method to update the delay value for the current type. Returns false if the health monitor is not enabled
    # or is not an http monitor, the new value if it succeeds, and raises an exception otherwise.
    def status_regex=(value)
      return false unless @enabled && ['HTTP','HTTPS'].include?(self.type)
      update(:type => self.type, :status_regex => value)
    end
    
    # Convenience method to update the delay value for the current type. Returns false if the health monitor is not enabled
    # or is not an http monitor, the new value if it succeeds, and raises an exception otherwise.
    def body_regex=(value)
      return false unless @enabled && ['HTTP','HTTPS'].include?(self.type)
      update(:type => self.type, :body_regex => value)
    end
    
    # Removes the current health monitor.  Returns true if successful, exception otherwise.
    #
    #     >> monitor.destroy!
    #     => true
    def destroy!
      response = @connection.lbreq("DELETE",@lbmgmthost,"#{@lbmgmtpath}/loadbalancers/#{CloudLB.escape(@load_balancer.id.to_s)}/healthmonitor",@lbmgmtport,@lbmgmtscheme)
      CloudLB::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      @enabled = false
      true
    end
  end
end
