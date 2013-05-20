module RestfulGeof

  class TableInfo

    def initialize(column_info)
      @column_info = column_info
    end

    attr_accessor :column_info

    def geometry_column
      column_info.map { |r| r[:column_name] if r[:udt_name] == "geometry" }.compact.first
    end

    def tsvector_columns
      column_info.map { |r| r[:column_name] if r[:udt_name] == "tsvector" }.compact
    end

    def normal_columns
      column_info.map { |r| r[:column_name] } - ([geometry_column] + tsvector_columns)
    end

    def integer_col?(name)
      col_type = column_info.select { |r| r[:column_name] == name }.first[:udt_name]
      %w{integer int smallint bigint int2 int4 int8}.include?(col_type)
    end

  end

end

