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
