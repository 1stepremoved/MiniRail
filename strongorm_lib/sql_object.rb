require_relative 'db_connection'
require_relative 'searchable'
require_relative 'associatable'
require 'active_support/inflector'

class SQLObject
  extend Searchable
  extend Associatable

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||=  self.to_s.tableize
    # @table_name = self.to_s.scan(/[A-Z][a-z]+/).map(&:downcase).join('_') + 's'
  end

  def self.columns
    return @columns if @columns
    @columns = DBConnection.execute2(<<-SQL)
        SELECT
          *
        FROM
          #{self.table_name}
        LIMIT
          0
    SQL
    @columns = @columns.first.map(&:to_sym)
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |col| attributes[col] }
  end

  def self.finalize!
    self.columns

    @columns.each do |column|
      define_method(column) do
        attributes[column]
      end

      define_method("#{column}=") do |value|
        attributes[column] = value
      end
    end
  end

  def initialize(params = {})
    self.class.finalize!
    params.each do |attr_name, value|
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name.to_sym)
      self.send("#{attr_name}=", value)
    end
  end

  def self.all
    rows = DBConnection.execute2(<<-SQL)
        SELECT
          #{@table_name}.*
        FROM
          #{@table_name};
    SQL

    rows = rows[1..-1]
    parse_all(rows)
  end

  def self.parse_all(results)
    results.map {|result| self.new(result)}
  end

  def self.find(id)
    row = DBConnection.execute2(<<-SQL, id)
        SELECT
          #{@table_name}.*
        FROM
          #{@table_name}
        WHERE
          #{@table_name}.id = ?;
    SQL
    row = row[1..-1]
    row.empty? ? nil : parse_all(row).first
  end

  def insert
    columns = self.class.columns.dup
    columns.delete(:id)
    question_marks = columns.map { "?" }.join(", ")
    columns = columns.map(&:to_s).join(", ")
    #first index of attribute_values is index, so it is not included
    DBConnection.execute2(<<-SQL, *attribute_values[1..-1])
      INSERT INTO
        #{self.class.table_name} (#{columns})
      VALUES
        (#{question_marks});
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    columns = self.class.columns.dup
    columns.delete(:id)
    columns = columns.map {|col| "#{col} = ?"}.join(", ")
    #first index of attribute values is index, which is interpolated last
    DBConnection.execute2(<<-SQL, *attribute_values.rotate)
      UPDATE
        #{self.class.table_name}
      SET
        #{columns}
      WHERE
        id = ?;
    SQL
  end

  def save
    self.id ? update : insert
  end
end
