require_relative 'sql_object'
require 'active_support/inflector'

class AssocOptions
  attr_accessor :foreign_key, :class_name, :primary_key

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @name = name
    @class_name = options[:class_name] || name.to_s.capitalize
    @foreign_key = options[:foreign_key] || (name.to_s.downcase + "_id").to_sym
    @primary_key = options[:primary_key] || :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @name = name
    @self_class_name = self_class_name
    @class_name = options[:class_name] || name.to_s.singularize.capitalize
    @foreign_key = options[:foreign_key] || (self_class_name.to_s.downcase + "_id").to_sym
    @primary_key = options[:primary_key] || :id
  end

end

module Associatable

  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    define_method(name) do
      # debugger
      return nil unless self.send(options.foreign_key) # TODO this should never return nil, why does it?
      options.model_class.where(options.primary_key => self.send(options.foreign_key)).first
    end
    self.assoc_options[name] = options
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    define_method(name) do
      options.model_class.where(options.foreign_key => self.send(options.primary_key))
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]
      start_table = source_options.model_class.table_name
      join_table1 = through_options.model_class.table_name
      result = DBConnection.execute2(<<-SQL)
          SELECT
            #{start_table}.*
          FROM
            #{source_options.model_class.table_name}
          JOIN
            #{join_table1} ON #{join_table1}.#{source_options.foreign_key} = #{start_table}.#{source_options.primary_key}
          WHERE
            #{self.owner_id} = #{through_options.model_class.table_name}.#{through_options.primary_key}
      SQL
      result = result[1..-1]
      source_options.model_class.parse_all(result).first
    end
  end
end
