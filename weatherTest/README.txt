Hola!

This is the directory where the weather data stuff lives:
		1. The zip->coords DB
		2. plist files for faux zip-codes
		3. temporary plist files for requested locations
		4. utility files for generating stuff:
			setupDB.sh
			free-zip-code-database.csv
			load_zipcodes.sql

To generate the zip->coords database, execute 'setupDB.sh' 
This will use the raw .csv file and the .sql file to generate the sqlite DB
  including the entries for faux zip-code(zipcodes for "canned" forcasts).

To created a faux-zip entry, open load_zipcodes.sql and added an INSERT line
  for the fake zipcode and make sure the corresponding plist file is in this
  directory(more details in the load_zipcodes.sql comments).
