# RestfulGeof - RESTful Geographic Features API

Talk to PostGIS in GeoJSON over HTTP.

## Implemented functionality

## Planned functionality

## Limitations

* Assumes zero or one geometry column per table
* Assumes geometry column, not geography
* At least one non-geometry column
* 'is' condition values will be treated as integers if possible, otherwise strings (can force string with digits only by URI encoding)

