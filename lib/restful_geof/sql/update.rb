module RestfulGeof
  module SQL
    class Update

      def initialize
        @parts = {
          :table => nil,
          :fields => [],
          :values => [],
          :where => nil,
          :returning => []
        }
      end

      def table(table_name)
        raise "Already specified table" if @parts[:table]
        @parts[:table] = table_name
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

      def where(condition)
        raise "Already specified where clause" if @parts[:where]
        @parts[:where] = condition
        self
      end

      def returning(*expressions)
        @parts[:returning] += [expressions].flatten
        self
      end

      alias_method :select, :returning

      def to_sql
        raise "Need to specify table" unless @parts[:table]
        raise "Need to specify fields" if @parts[:fields].empty?
        raise "Need to specify values" if @parts[:values].empty?
        raise "Need to specify where clause" unless @parts[:where]
        [
          update_clause,
          set_clause,
          where_clause,
          returning_clause
        ].compact.join("\n") + "\n;\n"
      end

      private

      def update_clause
        "UPDATE #{ @parts[:table] }"
      end

      def set_clause
        "SET (#{ @parts[:fields].join(", ") }) = (#{ @parts[:values].join(", ") })"
      end

      def where_clause
        "WHERE " + @parts[:where]
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

