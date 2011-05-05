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

      private

      def disconnect_connection(c)
        c.close
      end
    end
    
    class Dataset < Sequel::Dataset
      SELECT_CLAUSE_METHODS = clause_methods(:select, %w'distinct columns from join where group having compounds order limit')
      
      def fetch_rows(sql)
        execute(sql) do |result|
          begin
            width = result.first.size
            @columns = (0..width).to_a
            result.each do |r|
              row = {}
              r.each_with_index {|v, i| row[@columns[i]] = v}
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
