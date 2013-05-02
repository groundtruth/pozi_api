require "pg"
require "pg_typecast"
require "json"

module RestfulGeof
  class Store

    def initialize(database, table)
      @database = database
      @table = table
      options = { dbname: @database }
      options[:host] = ENV["RESTFUL_GEOF_PG_HOST"] || "localhost"
      options[:port] = ENV["RESTFUL_GEOF_PG_PORT"] || "5432"
      options[:user] = ENV["RESTFUL_GEOF_PG_USERNAME"] if ENV["RESTFUL_GEOF_PG_USERNAME"]
      options[:password] = ENV["RESTFUL_GEOF_PG_PASSWORD"] if ENV["RESTFUL_GEOF_PG_PASSWORD"]
      @connection = PG.connect(options)
    end

    def geometry_column
      @geometry_column = column_info.map { |r| r[:column_name] if r[:udt_name] == "geometry" }.compact.first
    end

    def tsvector_columns
      @tsvector_column = column_info.map { |r| r[:column_name] if r[:udt_name] == "tsvector" }.compact
    end

    def normal_columns
      @normal_columns = column_info.map { |r| r[:column_name] } - ([geometry_column] + tsvector_columns)
    end

    def create
    end

    def read
    end

    def find(conditions={})
      conditions[:is] ||= {}
      conditions[:matches] ||= {}

      where_conditions = (
        conditions[:is].map do |field, value|
          value_expression = value.kind_of?(Fixnum) ? value.to_s : "'#{ @connection.escape_string value }'"
          "#{ @connection.escape_string field } = #{ value_expression }"
        end +
        # []
        conditions[:matches].map do |field, value|
          "#{ @connection.escape_string field } @@ plainto_tsquery('#{ @connection.escape_string value }')"
        end
      ).join(", ")

      sql = <<-END_SQL
        SELECT
          #{normal_columns.join(", ")}
          #{ ", ST_AsGeoJSON(ST_Transform(#{geometry_column}, 4326)) AS geometry_geojson" if geometry_column }
        FROM #{@connection.escape_string @table}
        #{ "WHERE #{where_conditions}" unless where_conditions.empty? }
        #{ "LIMIT #{conditions[:limit]}" if conditions[:limit] }
        ;
      END_SQL

      as_feature_collection(@connection.exec(sql).to_a)
    end

    def update
    end

    def delete
    end

    private

    def column_info
      @column_fino ||= begin
        column_info_query = <<-END_SQL
          SELECT column_name, udt_name
          FROM information_schema.columns
          WHERE table_catalog = $1 AND table_name = $2;
        END_SQL
        @connection.exec(column_info_query, [@database, @table]).to_a
      end
    end

    def as_feature_collection(results)
      {
        "type" => "FeatureCollection",
        "features" => results.to_a.map do |row|
          {
            "type" => "Feature",
            "properties" => row.select { |k,v| k != :geometry_geojson }
          }.merge(
            begin
              if row[:geometry_geojson].to_s.empty?
                {}
              else
                { "geometry" => JSON.parse(row[:geometry_geojson]) }
              end
            end
          )
        end
      }.to_json
    end

  end
end

