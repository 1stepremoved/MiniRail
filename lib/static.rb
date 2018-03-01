require 'pathname'

class Static
  attr_reader :app

  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)
    if req.path =~ Regexp.new("^/public/.+$")
      res = Rack::Response.new
      parent_dir = File.expand_path("..",File.dirname(__FILE__))
      path = Pathname.new(File.join(parent_dir, *req.path.split("/")))
      if path.exist?
        res.write(path.read)
      else
        res.status = 404
      end
      res.finish
    else
      app.call(env)
    end
  end
end
