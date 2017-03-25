/* load_zipcodes.sql - SQL command to create our DB table load the .csv data *
*       fauxflag is '1' and plist is a filename if this is a "canned" entry *
*       For regular zipcode fauxflag=0 and plist is empty(or whatever)  */
CREATE TABLE zipcodes (zip INTEGER, 
			state STRING,
			city STRING,
			county STRING,
			latitude REAL,
			longitude REAL,
			PRIMARY KEY(zip));
.mode csv
.import noHeader.csv zipcodes
ALTER TABLE zipcodes ADD COLUMN fauxflag INTEGER;
UPDATE zipcodes SET fauxflag=0;
ALTER TABLE zipcodes ADD COLUMN plist STRING;
/* Here is where you add faux entries *
*    latitude and longitude should be zero *
*    fauxflag must be 1, and the plist file must exist if you expect to use *
*                    this zipcode entry.
*        All fields must be present so the db knows what column values go in */
INSERT INTO zipcodes VALUES (00001,'XXX','LaLaCity','LaLaLand',0,0,1,'lala.plist');
