module LoadBalancers
  class Node
    
    attr_reader :id
    attr_reader :address
    attr_reader :condition
    attr_reader :port
    attr_reader :weight
    attr_reader :status
    
    # Initializes a new LoadBalancers::Node object
    def initialize(load_balancer,id)
      @connection    = load_balancer.connection
      @load_balancer = load_balancer
      @id            = id
      @lbmgmthost   = @connection.lbmgmthost
      @lbmgmtpath   = @connection.lbmgmtpath
      @lbmgmtport   = @connection.lbmgmtport
      @lbmgmtscheme = @connection.lbmgmtscheme
      populate
      return self
    end
    
    # Updates the information about this LoadBalancers::Node object by making an API call.
    def populate
      response = @connection.lbreq("GET",@lbmgmthost,"#{@lbmgmtpath}/loadbalancers/#{LoadBalancers.escape(@load_balancer.id.to_s)}/nodes/#{LoadBalancers.escape(@id.to_s)}",@lbmgmtport,@lbmgmtscheme)
      LoadBalancers::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      data = JSON.parse(response.body)['node']
      @id                    = data["id"]
      @address                  = data["address"]
      @condition              = data["condition"]
      @port                  = data["port"]
      @weight             = data["weight"]
      @status                = data["status"]
      true
    end
    alias :refresh :populate
    
    # Allows you to change the condition of the current Node. Values should be either "ENABLED", "DISABLED", or "DRAINING"
    def condition=(data)
      (raise LoadBalancers::Exception::MissingArgument, "Must provide a new node condition") if data.to_s.empty?
      body = {"condition" => data.to_s.upcase}
      update(body)
    end
    
    # Deletes the current Node object and removes it from the load balancer. Returns true if successful, raises an exception if not.
    def destroy!
      response = @connection.lbreq("DELETE",@lbmgmthost,"#{@lbmgmtpath}/loadbalancers/#{LoadBalancers.escape(@load_balancer.id.to_s)}/nodes/#{LoadBalancers.escape(@id.to_s)}",@lbmgmtport,@lbmgmtscheme)
      LoadBalancers::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      true
    end
    
    private
    
    def update(data)
      body = {:node => data}
      response = @connection.lbreq("PUT", @lbmgmthost, "#{@lbmgmtpath}/loadbalancers/#{LoadBalancers.escape(@load_balancer.id.to_s)}/nodes/#{LoadBalancers.escape(@id.to_s)}",@lbmgmtport,@lbmgmtscheme,{},body.to_json)
      LoadBalancers::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      populate
      true
    end
    
  end
end
