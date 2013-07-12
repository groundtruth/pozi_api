module RestfulGeof
  module SQL
    class Insert

      def initialize
        @parts = {
          :into => nil,
          :fields => [],
          :values => [],
          :returning => []
        }
      end

      def into(table)
        raise "Already specified table" if @parts[:into]
        @parts[:into] = table
        self
      end

      def fields(fields)
        @parts[:fields] += [fields].flatten
        self
      end

      def values(values)
        @parts[:values] += [values].flatten
        self
      end

      def returning(*expressions)
        @parts[:returning] += [expressions].flatten
        self
      end

      alias_method :select, :returning

      def to_sql
        raise "Need to specify table" unless @parts[:into]
        [
          insert_clause,
          values_clause,
          returning_clause
        ].compact.join("\n") + "\n;\n"
      end

      private

      def insert_clause
        "INSERT INTO #{ @parts[:into] }(#{ @parts[:fields].join(", ") })"
      end

      def values_clause
        "VALUES (#{ @parts[:values].join(", ") })"
      end

      def returning_clause
        if @parts[:returning].empty?
          "RETURNING *"
        else
          "RETURNING " + @parts[:returning].join(", ")
        end
      end

    end
  end
end

