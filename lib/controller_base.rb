require 'active_support'
require 'active_support/core_ext'
require 'erb'
require 'json'
require_relative './session'
require_relative './flash'

class ControllerBase
  attr_reader :req, :res, :params

  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @already_built_response = false
    @params = route_params.merge(req.params)
    @@protect_from_forgery ||= false
  end

  def already_built_response?
    @already_built_response
  end

  def redirect_to(url)
    raise "Can't render/redirect twice" if already_built_response?
    res.status = 302
    res.location = url
    @already_built_response = true
    session.store_session(res)
    flash.store_flash(res)
  end

  def render_content(content, content_type)
    raise "Can't render/redirect twice" if already_built_response?
    res.write(content)
    res["Content-Type"] = content_type
    @already_built_response = true
    session.store_session(res)
    flash.store_flash(res)
  end

  def render(template_name)
    file_path = "views/" + self.class.to_s.underscore + "/" + template_name.to_s + ".html.erb"
    template = ERB.new(File.read(file_path)).result(binding)
    render_content(template, "text/html")
  end

  def session
    @session ||= Session.new(req)
    @session
  end

  def flash
    @flash ||= Flash.new(req)
    @flash
  end

  #router uses this to access methods defined on other controllers
  def invoke_action(name)
    if protect_from_forgery && req.request_method != "GET"
      check_authenticity_token
    else
      form_authenticity_token
    end
    self.send(name)
    render(name) unless @already_built_response
  end

  def form_authenticity_token
    @token ||= SecureRandom.urlsafe_base64(16)
    res.set_cookie("authenticity_token", {path: "/", value: @token})
    @token
  end

  def check_authenticity_token
    cookie = @req.cookies["authenticity_token"]
    unless cookie && cookie == params["authenticity_token"]
      raise "Invalid authenticity token"
    end
  end

  def self.protect_from_forgery
    @@protect_from_forgery = true
  end

  def protect_from_forgery
    @@protect_from_forgery
  end

end
