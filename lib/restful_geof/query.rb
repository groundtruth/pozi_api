module RestfulGeof

  class Query

    def initialize
      @parts = {
        :selects => [],
        :from => nil,
        :wheres => [],
        :order_bys => [],
        :limit => nil
      }
    end

    def select(*expressions)
      @parts[:selects] += [expressions].flatten
      self
    end

    def from(table)
      raise "Already specified table" if @parts[:from]
      @parts[:from] = table
      self
    end

    def where(*expressions)
      @parts[:wheres] += [expressions].flatten
      self
    end

    alias_method :and, :where

    def order_by(*expressions)
      @parts[:order_bys] += [expressions].flatten
      self
    end

    def limit(number)
      @parts[:limit] = number
      self
    end

    def to_sql
      raise "Need to specify table" unless @parts[:from]
      [
        select_clause,
        from_clause,
        where_clause,
        order_by_clause,
        limit_clause
      ].compact.join("\n") + "\n;\n"
    end

    private

    def select_clause
      if @parts[:selects].empty?
        "SELECT *"
      else
        "SELECT " + @parts[:selects].join(", ")
      end
    end

    def from_clause
      "FROM #{ @parts[:from] }"
    end

    def where_clause
      "WHERE " + @parts[:wheres].join(" AND ") unless @parts[:wheres].empty?
    end

    def order_by_clause
      "ORDER BY " + @parts[:order_bys].join(", ") unless @parts[:order_bys].empty?
    end

    def limit_clause
      "LIMIT #{ Integer(@parts[:limit]).to_s }" unless @parts[:limit].to_s.empty?
    end

  end

end

