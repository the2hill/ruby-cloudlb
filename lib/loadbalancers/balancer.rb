module LoadBalancers
  class Balancer
    
    attr_reader :id
    attr_reader :name
    attr_reader :protocol
    attr_reader :port
    attr_reader :connection
    attr_reader :algorithm
    attr_reader :connection_logging
    attr_reader :status
    
    # Creates a new LoadBalancers::Balancer object representing a Load Balancer instance.
    def initialize(connection,id)
      @connection    = connection
      @id            = id
      @lbmgmthost   = connection.lbmgmthost
      @lbmgmtpath   = connection.lbmgmtpath
      @lbmgmtport   = connection.lbmgmtport
      @lbmgmtscheme = connection.lbmgmtscheme
      populate
      return self
    end
    
    # Updates the information about the current Balancer object by making an API call.
    def populate
      response = @connection.lbreq("GET",@lbmgmthost,"#{@lbmgmtpath}/loadbalancers/#{LoadBalancers.escape(@id.to_s)}",@lbmgmtport,@lbmgmtscheme)
      LoadBalancers::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      data = JSON.parse(response.body)['loadBalancer']
      @id                    = data["id"]
      @name                  = data["name"]
      @protocol              = data["protocol"]
      @port                  = data["port"]
      @algorithm             = data["algorithm"]
      @connection_logging    = data["connectionLogging"]
      @status                = data["status"]
      true
    end
    alias :refresh :populate
  
    # Lists the virtual IP addresses associated with this Balancer
    #
    #    >> b.list_virtual_ips
    #    => [{:type=>"PUBLIC", :address=>"174.143.139.191", :ipVersion=>"IPV4", :id=>38}]
    def list_virtual_ips
      response = @connection.lbreq("GET", @lbmgmthost, "#{@lbmgmtpath}/loadbalancers/#{LoadBalancers.escape(@id.to_s)}/virtualips",@lbmgmtport,@lbmgmtscheme)
      LoadBalancers::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      LoadBalancers.symbolize_keys(JSON.parse(response.body)["virtualIps"])
    end
    
    # Lists the backend nodes that this Balancer sends traffic to.
    #
    #    >> b.list_nodes
    #    => [{:status=>"ONLINE", :port=>80, :address=>"173.203.218.1", :condition=>"ENABLED", :id=>1046}]
    def list_nodes
      response = @connection.lbreq("GET", @lbmgmthost, "#{@lbmgmtpath}/loadbalancers/#{LoadBalancers.escape(@id.to_s)}/nodes",@lbmgmtport,@lbmgmtscheme)
      LoadBalancers::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      LoadBalancers.symbolize_keys(JSON.parse(response.body)["nodes"])
    end
    
    # Returns a LoadBalancers::Node object for the given node id.
    def get_node(id)
      LoadBalancers::Node.new(self,id)
    end
    
    # Creates a brand new backend node and associates it with the current load balancer.  Returns the new Node object.
    #
    # Options include:
    #    * :address - The IP address of the backend node *required*
    #    * :port - The TCP port that the backend node listens on. *required*
    #    * :condition - Can be "ENABLED" (default), "DISABLED", or "DRAINING"
    #    * :weight - A weighting for the WEIGHTED_ balancing algorithms. Defaults to 1.
    def create_node(options={})
      (raise LoadBalancers::Exception::MissingArgument, "Must provide a node IP address") if options[:address].to_s.empty?
      (raise LoadBalancers::Exception::MissingArgument, "Must provide a node TCP port") if options[:port].to_s.empty?
      options[:condition] ||= "ENABLED"
      body = {:nodes => [options]}.to_json
      response = @connection.lbreq("POST", @lbmgmthost, "#{@lbmgmtpath}/loadbalancers/#{LoadBalancers.escape(@id.to_s)}/nodes",@lbmgmtport,@lbmgmtscheme,{},body)
      LoadBalancers::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      body = JSON.parse(response.body)['nodes'][0]
      return get_node(body["id"])
    end
      
    # Deletes the current load balancer object.  Returns true if successful, raises an exception otherwise.
    def destroy!
      response = @connection.lbreq("DELETE", @lbmgmthost, "#{@lbmgmtpath}/loadbalancers/#{LoadBalancers.escape(@id.to_s)}",@lbmgmtport,@lbmgmtscheme)
      LoadBalancers::Exception.raise_exception(response) unless response.code.to_s.match(/^202$/)
      true
    end
    
    # TODO: Figure out formats for startTime and endTime
    def usage
      response = @connection.lbreq("GET",@lbmgmthost,"#{@lbmgmtpath}/loadbalancers/#{LoadBalancers.escape(@id.to_s)}/usage",@lbmgmtport,@lbmgmtscheme,{})
      LoadBalancers::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      LoadBalancers.symbolize_keys(JSON.parse(response.body)["loadBalancerUsageRecords"])
    end
    
    # Returns either true or false if connection logging is enabled for this load balancer.
    #
    #    >> balancer.connection_logging?
    #    => false
    def connection_logging?
      response = @connection.lbreq("GET",@lbmgmthost,"#{@lbmgmtpath}/loadbalancers/#{LoadBalancers.escape(@id.to_s)}/connectionlogging",@lbmgmtport,@lbmgmtscheme,{})
      LoadBalancers::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      JSON.parse(response.body)["connectionLogging"]["enabled"]
    end
    
    # Pass either true or false in to enable or disable connection logging for this load balancer. Returns true if successful,
    # raises execption otherwise.
    #
    #     >> balancer.connection_logging = true
    #     => true
    def connection_logging=(state)
      (raise LoadBalancers::Exception::MissingArgument, "Must provide either true or false") unless [true,false].include?(state)
      body = {'connectionLogging' => {:enabled => state}}.to_json
      response = @connection.lbreq("PUT",@lbmgmthost,"#{@lbmgmtpath}/loadbalancers/#{LoadBalancers.escape(@id.to_s)}/connectionlogging",@lbmgmtport,@lbmgmtscheme,{}, body)
      LoadBalancers::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      true
    end

    # Sets a new name for the current load balancer.  Name must be 128 characters or less.
    def name=(new_name="")
      (raise LoadBalancers::Exception::Syntax, "Load balancer name must be 128 characters or less") if new_name.size > 128
      (raise LoadBalancers::Exception::MissingArgument, "Must provide a new name") if new_name.to_s.empty?
      body = {"name" => new_name}
      update(body)
    end
    
    # Sets a new balancer algorithm for the current load balancer. Must be a valid algorithm as returned by the
    # LoadBalancers::Connection.list_algorithms call.
    def algorithm=(new_algorithm="")
      (raise LoadBalancers::Exception::MissingArgument, "Must provide a new name") if new_algorithm.to_s.empty?
      body = {"algorithm" => new_algorithm.to_s.upcase}
      update(body)
    end
    
    # Sets a new port for the current load balancer to listen upon.
    def port=(new_port="")
      (raise LoadBalancers::Exception::MissingArgument, "Must provide a new port") if new_port.to_s.empty?
      (raise LoadBalancers::Exception::Syntax, "Port must be numeric") unless new_port.to_s =~ /^\d+$/
      body = {"port" => new_port.to_s}
      update(body)
    end
    
    # Sets a new protocol for the current load balancer to manage.  Must be a valid protocol as returned by the
    # LoadBalancers::Connection.list_protocols call.
    def protocol=(new_protocol="")
      (raise LoadBalancers::Exception::MissingArgument, "Must provide a new protocol") if new_protocol.to_s.empty?
      body = {"protocol" => new_protocol}
      update(body)
    end
    
    # Checks to see whether or not the load balancer is using HTTP cookie session persistence.  Returns true if it is, false otherwise.
    def session_persistence?
      response = @connection.lbreq("GET",@lbmgmthost,"#{@lbmgmtpath}/loadbalancers/#{LoadBalancers.escape(@id.to_s)}/sessionpersistence",@lbmgmtport,@lbmgmtscheme,{})
      LoadBalancers::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      JSON.parse(response.body)["sessionPersistence"]["persistenceType"] == "HTTP_COOKIE" ? true : false
    end
    
    # Allows toggling of HTTP cookie session persistence.  Valid values are true and false to enable or disable, respectively.
    def session_persistence=(value)
      (raise LoadBalancers::Exception::MissingArgument, "value must be true or false") unless [true,false].include?(value)
      if value == true
        body = {'sessionPersistence' => {'persistenceType' => 'HTTP_COOKIE'}}
        response = @connection.lbreq("POST", @lbmgmthost, "#{@lbmgmtpath}/loadbalancers/#{LoadBalancers.escape(@id.to_s)}/sessionpersistence",@lbmgmtport,@lbmgmtscheme,{},body.to_json)
      elsif value == false
        response = @connection.lbreq("DELETE", @lbmgmthost, "#{@lbmgmtpath}/loadbalancers/#{LoadBalancers.escape(@id.to_s)}/sessionpersistence",@lbmgmtport,@lbmgmtscheme)
      end
      LoadBalancers::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      true
    end
    
    # Returns the current access control list for the load balancer.
    def list_access_list
      response = @connection.lbreq("GET",@lbmgmthost,"#{@lbmgmtpath}/loadbalancers/#{LoadBalancers.escape(@id.to_s)}/accesslist",@lbmgmtport,@lbmgmtscheme,{})
      LoadBalancers::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      JSON.parse(response.body)["accessList"]
    end
    
    # FIXME: Does not work (JSON error)
    def add_to_access_list(options={})
      (raise LoadBalancers::Exception::MissingArgument, "Must supply address and type") unless (options[:address] && options[:type])
      body = {'networkItems' => [ { :address => options[:address], :type => options[:type].upcase}]}.to_json
      response = @connection.lbreq("POST",@lbmgmthost,"#{@lbmgmtpath}/loadbalancers/#{LoadBalancers.escape(@id.to_s)}/accesslist",@lbmgmtport,@lbmgmtscheme,{},body)
      LoadBalancers::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      true
    end
    
    # Deletes the entire access list for this load balancer, removing all entries. Returns true if successful, raises
    # an exception otherwise.
    #
    #     >> balancer.delete_access_list
    #     => true
    def delete_access_list
      response = @connection.lbreq("DELETE",@lbmgmthost,"#{@lbmgmtpath}/loadbalancers/#{LoadBalancers.escape(@id.to_s)}/accesslist",@lbmgmtport,@lbmgmtscheme,{})
      LoadBalancers::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      true
    end
    
    # TODO
    def delete_access_list_member(id)
      response = @connection.lbreq("DELETE",@lbmgmthost,"#{@lbmgmtpath}/loadbalancers/#{LoadBalancers.escape(@id.to_s)}/accesslist/#{LoadBalancers.escape(id.to_s)}",@lbmgmtport,@lbmgmtscheme,{})
      LoadBalancers::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      true
    end
    
    def get_health_monitor
      LoadBalancers::HealthMonitor.new(self)
    end
    
    def get_connection_throttle
      LoadBalancers::ConnectionThrottle.new(self)
    end
    
    private
    
    def update(body)
      response = @connection.lbreq("PUT", @lbmgmthost, "#{@lbmgmtpath}/loadbalancers/#{LoadBalancers.escape(@id.to_s)}",@lbmgmtport,@lbmgmtscheme,{},body.to_json)
      LoadBalancers::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      populate
      true
    end
      
    
  end  
end