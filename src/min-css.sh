#!/bin/bash

cat hackmysql.css | \
  tr "\n" " " | \
  sed -e 's#/\*[^\*]*\*/##g' | \
  sed -e 's/: /:/g' | \
  sed -e 's/{[ ]*/{/g' -e 's/[ ]*}/}/g' | \
  tr -s " " " " | \
  sed -e 's/ $/\n/' > ../static/hackmysql.css
