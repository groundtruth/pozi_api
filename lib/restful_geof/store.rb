require "pg"
require "pg_typecast"
require "json"

require "rgeo"
require "rgeo/geo_json"

require "restful_geof/table_info"
require "restful_geof/sql/query"
require "restful_geof/sql/insert"
require "restful_geof/sql/update"

module RestfulGeof

  class Store

    def initialize(database, table_name)
      options = { dbname: database }
      options[:host] = ENV["RESTFUL_GEOF_PG_HOST"] || "localhost"
      options[:port] = ENV["RESTFUL_GEOF_PG_PORT"] || "5432"
      options[:user] = ENV["RESTFUL_GEOF_PG_USERNAME"] if ENV["RESTFUL_GEOF_PG_USERNAME"]
      options[:password] = ENV["RESTFUL_GEOF_PG_PASSWORD"] if ENV["RESTFUL_GEOF_PG_PASSWORD"]
      @connection = PG.connect(options)

      @table_name = table_name

      @table_info = TableInfo.new(
        @connection.exec(
          SQL::Query.new.
            select("column_name", "udt_name").
            from("information_schema.columns").
            where("table_catalog = '#{ esc_s @connection.db }'").
            and("table_name = '#{ esc_s @table_name }'").to_sql
        ).to_a
      )
    end

    def create(data)
      feature = RGeo::GeoJSON.decode(data, :json_parser => :json)
      properties = Hash[feature.properties.map { |k,v| [esc_i(k), i_or_quoted_s_for(v, k)] }]

      insert = with_normal_and_geo_selects(SQL::Insert.new).into(esc_i(@table_name)).
        fields(properties.keys + [esc_i(@table_info.geometry_column)]).
        values(properties.values + ["ST_GeomFromText('#{ feature.geometry.as_text }', 4326)"])

      results = @connection.exec(insert.to_sql).to_a
      as_feature(results.first).to_json
    end

    def update(id, data)
      feature = RGeo::GeoJSON.decode(data, :json_parser => :json)
      properties = Hash[feature.properties.map { |k,v| [esc_i(k), i_or_quoted_s_for(v, k)] }]
      return [400, { error: "ID in payload doesn't match ID in URL" }.to_json ] unless feature.properties[@table_info.id_column].to_s == id.to_s

      update = with_normal_and_geo_selects(SQL::Update.new.table(esc_i(@table_name))).
        fields(properties.keys + [esc_i(@table_info.geometry_column)]).
        values(properties.values + ["ST_GeomFromText('#{ feature.geometry.as_text }', 4326)"]).
        where("#{ esc_i @table_info.id_column } = #{ i_or_quoted_s_for(id, @table_info.id_column) }")

      result = @connection.exec(update.to_sql)
      rows = result.to_a
      if result.cmd_status == "UPDATE 1" && rows.count == 1
        as_feature(rows.first).to_json
      else
        [400, { error: "Error updating" }.to_json]
      end
    end

    def read(id)
      query = with_normal_and_geo_selects(SQL::Query.new).
        where("#{ esc_i @table_info.id_column } = #{ i_or_quoted_s_for(id, @table_info.id_column) }").
        from(esc_i @table_name)
      results = @connection.exec(query.to_sql).to_a
      if results.count == 1
        as_feature(results.first).to_json
      else
        [404, {}.to_json]
      end
    end

    def delete(id)
      query_sql = <<-END_SQL
        DELETE FROM #{ esc_i @table_name }
        WHERE #{ esc_i @table_info.id_column } = #{ i_or_quoted_s_for(id, @table_info.id_column) };
      END_SQL
      result = @connection.exec(query_sql).cmd_status
      if result == "DELETE 1"
        [204, ""] # HTTP 204 No Content: The server successfully processed the request, but is not returning any content
      else
        [400, ""] # Don't have any more specific information
      end
    end

    def find(conditions={})
      conditions[:is] ||= {}
      conditions[:contains] ||= {}
      conditions[:matches] ||= {}

      query = with_normal_and_geo_selects(SQL::Query.new)

      query.from(esc_i @table_name)

      conditions[:is].each do |field, value|
        query.where "#{ esc_i field } = #{ i_or_quoted_s_for(value, field) }"
      end

      conditions[:contains].each do |field, value|
        query.where "#{ esc_i field }::varchar ILIKE '%#{ esc_s value.gsub(/(?=[%_])/, "\\") }%'"
        query.order_by "position(upper('#{ esc_s value }') in upper(#{ esc_i field }::varchar))"
      end

      conditions[:matches].each do |field, value|
        query.where <<-END_CONDITION
          #{ esc_i field } @@
          CASE
            WHEN char_length(plainto_tsquery('#{ esc_s value }')::varchar) > 0
            THEN to_tsquery(plainto_tsquery('#{ esc_s value }')::varchar || ':*')
            ELSE plainto_tsquery('#{ esc_s value }')
          END
        END_CONDITION
      end

      query.limit conditions[:limit]

      as_feature_collection(@connection.exec(query.to_sql).to_a).to_json
    end

    private

    def esc_i identifier
      @connection.escape_identifier(identifier)
    end

    def esc_s string
      @connection.escape_string(string)
    end

    def i_or_quoted_s_for value, field
      @table_info.integer_col?(field) ? Integer(value).to_s : "'#{ esc_s value }'"
    end

    def with_normal_and_geo_selects(query)
      query.select(@table_info.normal_columns)
      query.select("ST_AsGeoJSON(ST_Transform(#{@table_info.geometry_column}, 4326), 15, 2) AS geometry_geojson") if @table_info.geometry_column
      query
    end

    def as_feature(result)
      {
        "type" => "Feature",
        "properties" => result.select { |k,v| k != :geometry_geojson }
      }.merge(
        begin
          if result[:geometry_geojson].to_s.empty?
            {}
          else
            { "geometry" => JSON.parse(result[:geometry_geojson]) }
          end
        end
      )
    end

    def as_feature_collection(results)
      {
        "type" => "FeatureCollection",
        "features" => results.map { |result| as_feature(result) }
      }
    end

  end
end

