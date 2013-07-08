module RestfulGeof

  class TableInfo

    def initialize(column_info)
      @column_info = column_info
    end

    def geometry_column
      @column_info.map { |r| r[:column_name] if r[:udt_name] == "geometry" }.compact.first
    end

    def tsvector_columns
      @column_info.map { |r| r[:column_name] if r[:udt_name] == "tsvector" }.compact
    end

    def normal_columns
      @column_info.map { |r| r[:column_name] } - ([geometry_column] + tsvector_columns)
    end

    def integer_col?(name)
      col_type = @column_info.select { |r| r[:column_name] == name }.first[:udt_name]
      %w{integer int smallint bigint int2 int4 int8}.include?(col_type)
    end

    def id_column
      (normal_columns & %w{id ogc_fid ogr_fid fid}).first or
        integer_columns.first or
        raise("No id column could be identified among #{normal_columns.inspect}!")
    end

    private

    def integer_columns
      normal_columns.select { |col| integer_col?(col) }
    end

  end

end

