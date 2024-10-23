#!/bin/bash
curl https://api.usefathom.com/v1/aggregations \
  -G \
  -H "Authorization: Bearer $FA_TOKEN" \
  -H "Content-Type: application/json" \
  -d "entity=pageview" \
  -d "entity_id=WJIYGVMB" \
  -d "aggregates=pageviews" \
  -d "field_grouping=pathname" > out.json
#cat out.json | jq -s '.[] | sort_by(.pageviews|tonumber)'
cat out.json | jq '.[] | .pathname + ":" + .pageviews' | grep -v '/null' | grep -v '/archive' | sed 's/"//g' | sed -e 's#/post##g' | awk -F: '{ p[$1]+=$2} END { for (k in p) print k, p[k] }' | sort -k2 -n
