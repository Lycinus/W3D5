require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    columns = DBConnection::execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      LIMIT
        0
    SQL

    columns = columns.first.map!(&:to_sym)
    @columns = columns
  end

  def self.finalize!
    self.columns.each do |col|
      define_method(col) {attributes[col]}
      define_method("#{col}=") {|val| attributes[col] = val}
    end
  end

  def self.table_name=(name)
    @table_name = name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    all_objects = DBConnection.execute(<<-SQL)
    SELECT
      "#{table_name}".*
    FROM
      "#{table_name}"
    SQL

    self.parse_all(all_objects)
  end

  def self.parse_all(results)
    results.map {|hash| self.new(hash)}
  end

  def self.find(id)
    params = DBConnection.execute(<<-SQL)
    SELECT
      *
    FROM
      "#{table_name}"
    WHERE
      id = "#{id}"
    SQL

    return nil if params.empty?
    
    self.new(params.first)
  end

  def initialize(params = {})
    params.each do |attr_name, val|
      if !self.class.columns.include?(attr_name.to_sym)
        raise "unknown attribute '#{attr_name}'" 
      else
        self.send("#{attr_name}=", val)
      end
    end

  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    columns = self.class.columns.drop(1)
    col_names = columns.map(&:to_s).join(", ")
    question_marks = (["?"] * attribute_values.length).join(", ")
    
    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id

  end

  def update
    DBConnection.execute(<<-SQL, *attribute_values)
    UPDATE
      #{table_name}
    SET

    WHERE
      id = #{id}

    SQL
  end

  def save
    # ...
  end
end
