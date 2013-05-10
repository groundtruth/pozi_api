# RestfulGeof - RESTful Geographic Features API

Talk to PostGIS in GeoJSON over HTTP.

[![Build Status](https://travis-ci.org/groundtruth/restful_geof.png?branch=master)](https://travis-ci.org/groundtruth/restful%5Fgeof)


## Introduction

RestfulGeof aims to provide a simple, GeoJSON-based, RESTful HTTP API for
performing [CRUD](http://en.wikipedia.org/wiki/Create,_read,_update_and_delete)
operations and basic querying on spatial data in Postgres tables.

It is a generic tool that allows for specific APIs to be defined by running it
on purpose-built database tables.


## Setup

There are a couple of steps to setting up RestfulGeof.

### Getting the code

Get the code and run the full test suite as follows:

    git clone git://github.com/groundtruth/restful_geof.git && cd restful_geof
    bundle install
    bundle exec rspec spec

The integration tests assume there is a local database that can be accessed
as the current user, without a password, and that `psql` is on the path.

### Database

RestfulGeof works with PostgreSQL and the PostGIS extension. You'll need
to [install these](http://postgis.net/install/) or use a
[hosted instance](https://www.google.com/search?name=f&hl=en&q=hosted+postgis).

The database table or tables made available by RestfulGeof may have a geometry
column (none is okay, additional geometry columns will be ignored). This must
be a geometry column, not a geography column.

RestfulGeof can read colums of any SRID and will automatically transform them
for presentation in EPSG:3857 (web mercator).

There must be at least one non-geography column (e.g. `id`).

### Credentials

Database connection and authentication details default to the local instance
of Postgres, on the default port, with the current user's username and no
password.

These defaults can be overridden by setting the following environment variables:

    RESTFUL_GEOF_PG_HOST
    RESTFUL_GEOF_PG_PORT
    RESTFUL_GEOF_PG_USERNAME
    RESTFUL_GEOF_PG_PASSWORD

### Webserver

RestfulGeof is a rack app, and can be served in various ways. One option is to
use [Unicorn](http://unicorn.bogomips.org):

    git clone git://github.com/groundtruth/restful_geof.git && cd restful_geof
    bundle install
    bundle exec unicorn

You will probably want to use `config.ru` and/or your front-end web server
to add a prefix to the URL from which ResftfulGeof is served.

Note that RestfulGeof does not currently handle exceptions very gracefully.
Running in development mode will activate Sinatra's more verbose exception
handling, but may have drawbacks that make it inappropriate for your situation.


## Querying

You can query RestfulGeof by constructing a GET request with the following
URL path (`[]` indicates optional parts, `{}` indicates values to fill in):

    /{database}/{table}[/{conditions}][/limit/{max_results}]

Where `{conditions}` are one, or several (`/` separated) of the following:

    {field}/is/{value}
    {field}/matches/{value}

The `is` conditions will match a given field exactly (with ` = `). The value
part of an `is` condition will be cast to an integer if the database column
is of an integer type, otherwise it will be treated as a string.

The `matches` conditions will do a
[full-text search](http://www.postgresql.org/docs/9.2/static/textsearch.html)
match (with ` @@ `). The value given will be cast to a `tsquery` using
`plainto_tsquery()`. To allow for autocomplete functionality, the query will be
adjusted so that the final search term can match as a prefix.

Here are a some examples:

    /citydb/offices
    /citydb/addresses/limit/1000
    /citydb/addresses/propertyid/is/2340982
    /citydb/addresses/ts_full_address/matches/22%20high%20st/limit/10
    /citydb/addresses/collection_day/is/Monday/ts_full_address/matches/high%20st/limit/1000


## Planned functionality

* Accept database authentication credentials from HTTP headers.
* Read an individual feature by ID (e.g. `GET /api/database/table/22`).
* Find features closest to a point, or within a bounding box.
* Create new features.
* Update existing features.
* Delete existing features.
* Return results in a JSONP wrapper.
* Built-in CORS support.
* Add [Code Climate](https://codeclimate.com) metrics.
* Allow limit condition earlier in request URL.
* Extend README with an example of running RestfulGeof on Heroku.


## Copyright

RestfulGeof was created by [Groundtruth](http://groundtruth.com.au/)
and is offered under the [MIT License](http://opensource.org/licenses/MIT).

