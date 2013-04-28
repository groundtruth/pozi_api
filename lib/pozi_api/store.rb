require "pg"
require "json"

module PoziAPI
  class Store

    def initialize(database, table)
      @database = database
      @table = table
      options = { dbname: @database }
      options[:host] = ENV["POZI_API_PG_HOST"] || "localhost"
      options[:port] = ENV["POZI_API_PG_PORT"] || "5432"
      @connection = PG.connect(options)
    end

    def geometry_column
      @geometry_column = column_info.map { |r| r["column_name"] if r["udt_name"] == "geometry" }.compact.first
    end

    def non_geometry_columns
      @non_geometry_columns = column_info.map { |r| r["column_name"] } - [geometry_column]
    end

    def create
    end

    def read
      as_feature_collection(@connection.exec(
        <<-END_SQL
          SELECT
            #{non_geometry_columns.join(", ")}
            #{ ", ST_AsGeoJSON(ST_Transform(#{geometry_column}, 4326)) AS geometry_geojson" if geometry_column }
          FROM #{@connection.escape_string @table}; 
        END_SQL
      ))
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
            "properties" => row.select { |k,v| k != "geometry_geojson" }
          }.merge(
            begin
              if row["geometry_geojson"].to_s.empty?
                {}
              else
                { "geometry" => JSON.parse(row["geometry_geojson"]) }
              end
            end
          )
        end
      }.to_json
    end

  end
end

