require 'json'

class Flash
  attr_reader :now

  def initialize(req)
    cookie = req.cookies['_rails_lite_app_flash']

    @now = cookie ? JSON.parse(cookie) : {}
    @flash = {}
    #all the values in flash cookie will be passed into now when a new request is made
    #since we can't tell where things are stored when we access them it doesn't matter
    #we don't store values from now, so they only persist one session
  end

  def [](key)
    @now[key.to_s] || @flash[key.to_s]
  end

  def []=(key,val)
    @flash[key.to_s] = val
  end

  def store_flash(res)
    res.set_cookie("_rails_lite_app_flash", {path: "/", value: @flash.to_json})
  end

end
