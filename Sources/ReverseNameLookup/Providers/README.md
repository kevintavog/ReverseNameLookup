A new ElasticSearch index should have at least this configuration:


{
    "settings": {
      "index": {
        "number_of_shards": "1",
        "number_of_replicas": "0"
      }
    },
    "mappings": {
      "entry": {
        "properties": {
          "date_retrieved": {
            "type": "date"
          },
          "location": {
            "type": "geo_point"
          }
        }
      }
    }
}


Copying from Jupiter:
Setup the map first, as this tool seemed to mess up the location (two floats, rather than a geo_point)
elasticdump --input=http://jupiter/elasticsearch --input-index=azure_placenames_cache --output=http://localhost:9200 --output-index=azure_placenames_cache
