require 'rack'
require_relative './lib/controller_base.rb'
require_relative './lib/router'
require_relative './lib/show_exceptions'
require_relative './lib/static'
require_relative './strongorm_lib/strong_orm.rb'
Dir["./controllers/*.rb"].each {|file| require file}
require_relative "./config/routes.rb"

router = Router.new

router.draw(&ROUTES)

app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  router.run(req, res)
  res.finish
end

app = Rack::Builder.new do
  use ShowExceptions
  use Static
  run app
end.to_app

Rack::Server.start(
 app: app,
 Port: 3000
)
