#!/bin/bash
curl https://api.usefathom.com/v1/aggregations \
  -G \
  -H "Authorization: Bearer $FA_TOKEN" \
  -H "Content-Type: application/json" \
  -d "entity=pageview" \
  -d "entity_id=WJIYGVMB" \
  -d "aggregates=pageviews" \
  -d "field_grouping=pathname" > out.json
cat out.json | jq -s '.[] | sort_by(.pageviews|tonumber)'
