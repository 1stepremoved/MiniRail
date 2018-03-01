require 'pry'
require_relative './sql_object'
require 'active_support/inflector'


DBConnection.reset

DBConnection.tables.each do |table_name|
  const = Object.const_set(table_name.singularize.camelize, Class.new(SQLObject))
  const.table_name = table_name
end

Dir[File.expand_path("../../models", __FILE__)+"/*.rb"].each {|file| require file }
