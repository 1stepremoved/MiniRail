class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name

  def initialize(pattern, http_method, controller_class, action_name)
    @pattern = pattern
    @http_method = http_method
    @controller_class = controller_class
    @action_name = action_name
  end

  def matches?(req)
    req.path =~ @pattern && @http_method.to_s.upcase == req.request_method
  end

  def run(req, res)
    match = @pattern.match(req.path)
    params = {}
    match.names.each do |name|
      params[name] = match[name]
    end
    @controller_class.new(req,res,params).invoke_action(@action_name)
  end
end

class Router
  attr_reader :routes

  def initialize
    @routes = []
  end

  def add_route(pattern, method, controller_class, action_name)
    @routes << Route.new(pattern,method,controller_class,action_name)
  end

  # evaluate the proc in the context of the instance
  def draw(&proc)
    self.instance_eval(&proc)
  end

  [:get, :post, :put, :patch, :delete].each do |http_method|
    define_method(http_method) do |*args|
      add_route(args[0], http_method, args[1], args[2])
    end
  end

  def match(req)
    @routes.each do |route|
      return route if route.matches?(req)
    end
    nil
  end

  def run(req, res)
    route = match(req)
    if route
      route.run(req,res)
    else
      res.status = 404
    end
  end
end
