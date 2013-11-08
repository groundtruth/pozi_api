# RestfulGeof - RESTful Geographic Features API

Talk to PostGIS in GeoJSON over HTTP.

[![Build Status](https://travis-ci.org/groundtruth/restful_geof.png?branch=master)](https://travis-ci.org/groundtruth/restful%5Fgeof)
[![Code Climate](https://codeclimate.com/github/groundtruth/restful_geof.png)](https://codeclimate.com/github/groundtruth/restful%5Fgeof)


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

The integration tests assume there is a local database with PostGIS that can
be accessed as the current user, without a password ('trust' METHOD), and that 
`psql` is on the path.

RestfulGeof uses the RGeo gem, which depends on GEOS and Proj.
More info [on the RGeo page](https://github.com/dazuma/rgeo#dependencies).

It is built for Ruby 1.9.

### Database

RestfulGeof works with PostgreSQL and the PostGIS extension. You'll need
to [install these](http://postgis.net/install/) or use a
[hosted instance](https://www.google.com/search?name=f&hl=en&q=hosted+postgis).

The database table or tables made available by RestfulGeof must have an ID
column. RestfulGeof will look for a column named `id`, `ogc_fid`, `ogr_fid`,
or `fid`, or for the first integer column, and will use the first one it finds
as the ID column. RestfulGeof does not allocate new ID values - this should be
handled by database constraints.

There may be a geometry column (none is okay, additional geometry columns will
be ignored). This must be a geometry column, not a geography column.

RestfulGeof can read colums of any SRID and will automatically transform them
for presentation in WGS84 (EPSG:4326).

There must be at least one non-geometry column (e.g. `id`).

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

RestfulGeof is a rack app and can be served in various ways. One option is to
use [Unicorn](http://unicorn.bogomips.org):

    git clone git://github.com/groundtruth/restful_geof.git && cd restful_geof
    bundle install
    bundle exec unicorn

You will probably want to use `config.ru` and/or your front-end web server
to add a prefix to the URL from which ResftfulGeof is served.


## Querying

You can query RestfulGeof by constructing a `GET` request with the following
URL path (`[]` indicates optional parts, `{}` indicates values to fill in):

    /{database}/{table}[/{conditions}][/limit/{max_results}]

Where `{conditions}` are one, or several (`/` separated) of the following:

    {field}/is/{value}
    {field}/in/{value1},{value2},{valueN}
    {field}/contains/{value}
    {field}/matches/{value}
    closest/{longitude}/{latitude}
    {distance}/maround/{longitude}/{latitude}

The `is` conditions will match a given field exactly (with ` = `). The value
part of an `is` condition will be cast to an integer if the database column
is of an integer type, otherwise it will be treated as a string.

The `in` conditions will match a given field against a list of values. The
values can be integers or string and should be separated by commas. A string
including a comma (or other special characters) can be specified by URL encoding
it.

The `contains` conditions will match if the value string is found within the
given field. This is case insensitive and results will be returned earlier if
the match is further to the left. The intention of this is to provide basic
querying for autocomplete, where full-text search (see below) is not
appropriate. Note that this kind of query can not be aided by an index so it
will perform poorly on large datasets.

The `matches` conditions will do a
[full-text search](http://www.postgresql.org/docs/9.2/static/textsearch.html)
match (with ` @@ `). The value given will be cast to a `tsquery` using
`plainto_tsquery()`. To allow for autocomplete functionality, the query is
adjusted so that the final search term can match as a prefix.

A `closest` condition will order found features by distance from the given
point. This is best used in conjunction with a limit.

Here are a some examples:

    /citydb/offices
    /citydb/addresses/limit/1000
    /citydb/addresses/limit/1000
    /citydb/addresses/closest/141.584379916592/-36.3419002991608/limit/20
    /citydb/addresses/propertyid/is/2340982
    /citydb/addresses/propertyid/in/232,236,237
    /citydb/addresses/full_address/contains/22%20high/limit/10
    /citydb/addresses/collection_day/is/Monday/report/matches/broken/limit/1000


## CRUD

Create a new record by doing a `POST` to:

    /{database}/{table}

with a single GeoJSON `Feature` as the request body. The created record will
be returned (including additional fields, such as an ID) if the action was
successful.

Read a specific record by performing a `GET` request of the form:

    /{database}/{table}/{id}

For example:

    /citydb/properties/223423

This will return the result as a single GeoJSON `Feature` (or HTTP status 404
if a record could not be identified).

A record can be updated by doing a `PUT` request to the same URL. The
body should be a full GeoJSON `Feature` (not just fields to be modified).

A `DELETE` request with no body will delete a record, and return a status
code of 204 if the action was successful.


## Planned functionality

* Improve error message generated by accessing an unreadble table.
* Impelement all pending specs.
* Figure out good settings for prod/other exception handling.
* Find features within a bounding box.
* Accept database authentication credentials from HTTP headers.
* Extend README with an example of running RestfulGeof on Heroku.
* Built-in CORS support.
* Allow limit condition earlier in the request URL.


## Copyright

The [MIT License](http://opensource.org/licenses/MIT) (MIT)

Copyright (c) 2013 [Groundtruth](http://groundtruth.com.au/)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

Comments and contributions are welcome.

