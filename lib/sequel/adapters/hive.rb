require 'rbhive'

module Sequel
  module Hive
    class Database < Sequel::Database
      set_adapter_scheme :hive
      self.quote_identifiers = false
      self.identifier_input_method = :downcase
      
      def connect(server)
        opts = server_opts(server)
        RBHive::Connection.new(opts[:host], opts[:port] || 10_000)
      end
      
      def dataset(opts = nil)
        Hive::Dataset.new(self, opts)
      end
    
      def execute(sql, opts={})
        synchronize(opts[:server]) do |conn|
          conn.open
          r = log_yield(sql){conn.fetch(sql)}
          yield(r) if block_given?
          r
        end
      end
      alias_method :do, :execute
      
      def schema(table, opts={})
        hero = execute("DESCRIBE #{table}")
        hero[2..-1].map do |h|
          [h.first.strip, {:db_type => h[1].strip.to_sym, :type => h[1].strip.to_sym}]
        end
      end

      def tables(opts={})
        execute('SHOW TABLES')
      end

      private

      def disconnect_connection(c)
        c.close
      end
    end
    
    class Dataset < Sequel::Dataset
      SELECT_CLAUSE_METHODS = clause_methods(:select, %w'distinct columns from join where group having compounds order limit')

       CONVERT_FROM = { :string => :to_s, :bigint => :to_i }

      def schema
        @schema || @schema = @db.schema(@opts[:from].first)
      end

      def columns
        return @columns if @columns
        if @opts[:select].nil? || @opts[:select].include?(:*)
          @columns = schema.map{|c| c.first}
        else
          @columns = @opts[:select]
        end
      end

      def convert_type(column)
        db_type = @schema.select{|a| a.first == column}.first.last[:db_type]
        CONVERT_FROM[db_type]
      end
      
      def fetch_rows(sql)
        execute(sql) do |result|
          begin
            width = result.first.size
            result.each do |r|
              row = {}
              r.each_with_index {|v, i| row[columns[i]] = v.send(convert_type(columns[i]))}
              yield row
            end
          ensure
            #  result.close
          end
        end
        self
      end
      
      private
      
      def select_clause_methods
        SELECT_CLAUSE_METHODS
      end
    end
  end
end
