require_relative 'db_connection'
require 'active_support/inflector'
#NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
#    of this project. It was only a warm up.

class SQLObject
  def self.columns
    columns = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    columns.first.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |column|
      define_method(column) { attributes[column.to_sym] }
      define_method("#{column}=") do |set_name|
        attributes[column.to_sym] = set_name
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    query = <<-SQL
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        #{table_name}.id = ?
    SQL
    results = DBConnection.execute(query, id)

    parse_all(results).first
  end

  def attributes
    @attributes
  end

  def insert
    table_name = self.class.table_name
    columns = self.class.columns.join(', ')
    values = (['?'] * self.class.columns.size).join(', ')

    query = <<-SQL
      INSERT INTO
        #{table_name} (#{columns})
      VALUES
        (#{values})
    SQL

    DBConnection.execute(query, attribute_values)
    attributes[:id] = DBConnection.last_insert_row_id
  end

  def initialize(params={})
    @attributes = {}
    self.class.columns.each do |column|
      @attributes[column.to_sym] = nil
    end

    params.each do |attr_name, value|
      raise "unknown attribute '#{attr_name}'" unless @attributes.keys.include?(attr_name.to_sym)
      send("#{attr_name}=".to_sym, value)
    end
  end

  def save
    attributes[:id] ? update : insert
  end

  def update
    table_name = self.class.table_name
    set_line = self.class.columns.map { |attr_name| "#{attr_name} = ?" }.join(', ')
    id = attributes[:id]

    query = <<-SQL
      UPDATE
        #{table_name}
      SET
        #{set_line}
      WHERE
        id = ?
    SQL

    DBConnection.execute(query, attribute_values, id)
  end

  def attribute_values
    self.class.columns.map { |column| send(column) }
  end
end
