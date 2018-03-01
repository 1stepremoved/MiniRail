require 'erb'

class ShowExceptions
  attr_reader :app

  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      app.call(env)
    rescue => e
      res = Rack::Response.new
      content = render_exception(e)
      res.status = 500
      res.write(content)
      res["Content-type"] = "text/html"
      res.finish
    end
  end

  private

  def render_exception(e)
    file_path = "lib/templates/rescue.html.erb"
    template = ERB.new(File.read(file_path)).result(binding)
  end

  def source_file_name(e)
    e.backtrace.each do |line|
      return line.split(":")[0] if File.exist?(line.split(":")[0])
    end
    #should perhaps return a default file if one isn't found
  end

  def source_file_line_num(e)
    e.backtrace.first.split(":")[1]
  end

  def source_file(e)
    File.readlines(source_file_name(e)).map(&:chomp)
  end

end
