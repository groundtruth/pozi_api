require "ostruct"
require "pg"
require "pg_typecast"
require "patches/pg_typecast/pg_result"
require "json"

require "rgeo"
require "rgeo/geo_json"

require "restful_geof/table_info"
require "restful_geof/sql/query"
require "restful_geof/sql/insert"
require "restful_geof/sql/update"

module RestfulGeof

  class Store

    class Outcome
      def self.good(info={})
        OpenStruct.new({ okay?: true, data: {} }.merge(info))
      end
      def self.bad(info={})
        OpenStruct.new({ okay?: false, problem: "Unknown" }.merge(info))
      end
    end

    def initialize(database, table_name)
      options = { dbname: database }
      options[:host] = ENV["RESTFUL_GEOF_PG_HOST"] || "localhost"
      options[:port] = ENV["RESTFUL_GEOF_PG_PORT"] || "5432"
      options[:user] = ENV["RESTFUL_GEOF_PG_USERNAME"] if ENV["RESTFUL_GEOF_PG_USERNAME"]
      options[:password] = ENV["RESTFUL_GEOF_PG_PASSWORD"] if ENV["RESTFUL_GEOF_PG_PASSWORD"]
      @connection = PG.connect(options)

      @table_name = table_name

      info_query = SQL::Query.new.
        select("column_name", "udt_name", "srid").
        from("information_schema.columns c LEFT OUTER JOIN geometry_columns g ON g.f_table_name=c.table_name AND g.f_table_catalog=c.table_catalog AND g.f_geometry_column=c.column_name").
        where("c.table_catalog = '#{ esc_s @connection.db }'").
        and("c.table_name = '#{ esc_s @table_name }'").to_sql
      result = @connection.exec(info_query)

      rows = result.to_a
      if rows.count == 0
        raise "Could not get table info for #{@connection.db}.#{@table_name}. "+
              "res_status: '#{result.res_status}' "+
              "cmd_status: '#{result.cmd_status}' "+
              "error_message: '#{result.error_message}' "+
              "sql: '#{info_query}'"
      end
      @table_info = TableInfo.new(rows)

      if block_given?
        yield self
        @connection.close
      end
    end

    def create(params)
      feature = RGeo::GeoJSON.decode(params[:body_json], :json_parser => :json)
      properties = Hash[feature.properties.map { |k,v| [esc_i(k), i_or_quoted_s_for(v, k)] }]

      if @table_info.geometry_column
        properties[esc_i(@table_info.geometry_column)] = "ST_GeomFromText('#{ feature.geometry.as_text }', 4326)"
      end

      insert = with_normal_and_geo_selects(SQL::Insert.new).into(esc_i(@table_name)).
        fields(properties.keys).
        values(properties.values)

      # TODO: add checking of cmd_status here
      results = @connection.exec(insert.to_sql).to_a
      Outcome.good(data: as_feature(results.first))
    end

    def update(params)
      feature = RGeo::GeoJSON.decode(params[:body_json], :json_parser => :json)
      properties = Hash[feature.properties.map { |k,v| [esc_i(k), i_or_quoted_s_for(v, k)] }]

      unless feature.properties[@table_info.id_column].to_s == params[:id].to_s
        return Outcome.bad(problem: "ID in payload doesn't match ID in URL")
      end

      if @table_info.geometry_column
        properties[esc_i(@table_info.geometry_column)] = "ST_GeomFromText('#{ feature.geometry.as_text }', 4326)"
      end

      update = with_normal_and_geo_selects(SQL::Update.new.table(esc_i(@table_name))).
        fields(properties.keys).
        values(properties.values).
        where("#{ esc_i @table_info.id_column } = #{ i_or_quoted_s_for(params[:id], @table_info.id_column) }")

      result = @connection.exec(update.to_sql)
      rows = result.to_a
      if result.cmd_status == "UPDATE 1" && rows.count == 1
        Outcome.good(data: as_feature(rows.first))
      else
        Outcome.bad
      end
    end

    def read(params)
      query = with_normal_and_geo_selects(SQL::Query.new).
        where("#{ esc_i @table_info.id_column } = #{ i_or_quoted_s_for(params[:id], @table_info.id_column) }").
        from(esc_i @table_name)
      results = @connection.exec(query.to_sql).to_a
      if results.count == 1
        Outcome.good(data: as_feature(results.first))
      else
        Outcome.bad(problem: "Not found")
      end
    end

    def delete(params)
      query_sql = <<-END_SQL
        DELETE FROM #{ esc_i @table_name }
        WHERE #{ esc_i @table_info.id_column } = #{ i_or_quoted_s_for(params[:id], @table_info.id_column) };
      END_SQL
      if @connection.exec(query_sql).cmd_status == "DELETE 1"
        Outcome.good
      else
        Outcome.bad
      end
    end

    def query(params={ :conditions => {} })
      # TODO: clarify naming of conditions, options, query.

      params[:conditions][:is] ||= {}
      params[:conditions][:in] ||= {}
      params[:conditions][:contains] ||= {}
      params[:conditions][:matches] ||= {}
      params[:conditions][:closest] ||= {}
      params[:conditions][:maround] ||= {}

      query = with_normal_and_geo_selects(SQL::Query.new)

      query.from(esc_i @table_name)

      unless params[:conditions][:maround].empty?
        lon = Float(params[:conditions][:maround][:lon])
        lat = Float(params[:conditions][:maround][:lat])
        query.where <<-END_CONDITION
          ST_Intersects(
            ST_Transform(
              ST_Buffer(
                ST_Transform(ST_GeomFromText('POINT(#{ lon } #{ lat })', 4326), 3857), 
                #{ Float(params[:conditions][:maround][:radius]) },
                'quad_segs=16'
              ),
              #{@table_info.geometry_srid}
            ),
            #{@table_info.geometry_column}
          )
        END_CONDITION
      end

      ordering_point = nil
      if params[:conditions][:closest][:lat] && params[:conditions][:closest][:lon]
        ordering_point = params[:conditions][:closest]
      elsif params[:conditions][:maround][:lat] && params[:conditions][:maround][:lon]
        ordering_point = params[:conditions][:maround]
      end

      if ordering_point
        query.order_by <<-END_CONDITION
          #{@table_info.geometry_column} <-> ST_Transform(ST_GeomFromText('POINT(#{ Float(ordering_point[:lon]) } #{ Float(ordering_point[:lat]) })', 4326),#{@table_info.geometry_srid})
        END_CONDITION
      end

      params[:conditions][:is].each do |field, value|
        query.where "#{ esc_i field } = #{ i_or_quoted_s_for(value, field) }"
      end

      params[:conditions][:in].each do |field, values|
        query.where "#{ esc_i field } IN (#{ values.map { |v| i_or_quoted_s_for(v, field) }.join(", ") })"
      end

      params[:conditions][:contains].each do |field, value|
        query.where "#{ esc_i field }::varchar ILIKE '%#{ esc_s value.gsub(/(?=[%_])/, "\\") }%'"
        query.order_by "position(upper('#{ esc_s value }') in upper(#{ esc_i field }::varchar))"
        query.order_by "#{ esc_i field }::varchar"
      end

      params[:conditions][:matches].each do |field, value|
        query.where <<-END_CONDITION
          #{ esc_i field } @@
          CASE
            WHEN char_length(plainto_tsquery('#{ esc_s value }')::varchar) > 0
            THEN to_tsquery(plainto_tsquery('#{ esc_s value }')::varchar || ':*')
            ELSE plainto_tsquery('#{ esc_s value }')
          END
        END_CONDITION
      end

      query.limit params[:conditions][:limit]

      Outcome.good(data: as_feature_collection(@connection.exec(query.to_sql).to_a))
    end

    private

    def esc_i identifier
      @connection.escape_identifier(identifier) if identifier
    end

    def esc_s string
      @connection.escape_string(string)
    end

    def i_or_quoted_s_for value, field
      if @table_info.integer_col?(field)
        value.to_s.empty? ? "NULL" : Integer(value).to_s
      else
        "'#{ esc_s value }'"
      end
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

