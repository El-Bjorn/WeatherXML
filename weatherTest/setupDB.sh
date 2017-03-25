#!/bin/bash

echo "blowing away old DB file..."
rm -f zipToCoords.db
echo "stripping out the header (column names) out of csv file..."
tail -n +2 free-zip-code-database.csv > noHeader.csv
echo "making the table and reading the data..."
cat load_zipcodes.sql | sqlite3 zipToCoords.db
echo "cleanup."
rm -f noHeader.csv # cleanup
