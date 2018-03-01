require_relative 'db_connection'

module Searchable
  def where(params)
    is_str = Proc.new {|s| s.is_a?(String) ? "'#{s}'" : "#{s}"}
    if (params.class == String)
      where_line = params
    else
      where_line = params.to_a.map {|pair| "#{@table_name}.#{pair[0]} = #{is_str.call(pair[1])}"}.join(" AND ")
    end
    rows = DBConnection.execute2(<<-SQL)
        SELECT
          #{@table_name}.*
        FROM
          #{@table_name}
        WHERE
          #{where_line}
    SQL
    rows = rows[1..-1]
    parse_all(rows)
  end
end
