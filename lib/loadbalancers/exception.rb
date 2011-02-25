module LoadBalancers
  class Exception

    class LoadBalancersError < StandardError

      attr_reader :response_body
      attr_reader :response_code

      def initialize(message, code, response_body)
        @response_code=code
        @response_body=response_body
        super(message)
      end

    end
    
    class LoadBalancerFault           < LoadBalancersError # :nodoc:
    end
    class ServiceUnavailable          < LoadBalancersError # :nodoc:
    end
    class Unauthorized                < LoadBalancersError # :nodoc:
    end
    class BadRequest                  < LoadBalancersError # :nodoc:
    end
    class OverLimit                   < LoadBalancersError # :nodoc:
    end
    class Other                       < LoadBalancersError # :nodoc:
    end
    
    # Plus some others that we define here
    
    class ExpiredAuthToken            < StandardError # :nodoc:
    end
    class MissingArgument             < StandardError # :nodoc:
    end
    class Authentication              < StandardError # :nodoc:
    end
    class Connection                  < StandardError # :nodoc:
    end
    class Syntax                      < StandardError # :nodoc:
    end
    
        
    # In the event of a non-200 HTTP status code, this method takes the HTTP response, parses
    # the JSON from the body to get more information about the exception, then raises the
    # proper error.  Note that all exceptions are scoped in the LoadBalancers::Exception namespace.
    def self.raise_exception(response)
      return if response.code =~ /^20.$/
      begin
        fault = nil
        info = nil
        JSON.parse(response.body).each_pair do |key, val|
			    fault=key
			    info=val
			  end
        exception_class = self.const_get(fault[0,1].capitalize+fault[1,fault.length])
        raise exception_class.new(info["message"], response.code, response.body)
      rescue NameError, JSON::ParserError
        raise LoadBalancers::Exception::Other.new("The server returned status #{response.code} with body #{response.body}", response.code, response.body)
      end
    end
    
  end
end

