#!/usr/bin/perl -w  

# args: latitude longitude num_hours city state
# NOTE: if you get a divide by zero error, request a longer interval. I.e. more hours

use XML::XPath;
use DateTime::Format::XSD;
use Weather::NWS::NDFDgen;
use POSIX;

# Here is where you specify the weatherDB directory
$weatherDB = "/Users/bjornchambless/gitHub_repositories/SIGGRAPH/SIGGRAPH-2013/weatherXML/weatherDB";


if ($#ARGV <4){
	print STDERR "Too few args. Required args: latitude longitude numHours city state\n";
	exit(0);
}

$latitude = $ARGV[0];
$longitude = $ARGV[1];
$num_hours = $ARGV[2];
$city = $ARGV[3];
$state = $ARGV[4];

if ($num_hours < 6){
	print STDERR "don't use less than 6 hours or we may not get a reading for parameters\n";
	exit(0);
}
#print STDERR "current time: ".time()."\n";
## generate improbable filename
$plist_filename = "weatherTmp_".$state.time().".plist";
print STDERR "file: $plist_filename\n";

print STDERR "generating $num_hours hour forecast for $city, $state at $latitude,$longitude...\n";

# specify location we want
$NDFDgen = Weather::NWS::NDFDgen->new();
$NDFDgen->set_latitude($latitude);
$NDFDgen->set_longitude($longitude);
# type of forecast
$NDFDgen->set_product('Time-Series');

# set the time interval
$dt = DateTime->now();
$start_time = DateTime::Format::XSD->format_datetime($dt);
$NDFDgen->set_start_time($start_time);
$dt->add( hours => $num_hours );
$end_time = DateTime::Format::XSD->format_datetime($dt);
$NDFDgen->set_end_time($end_time);

# the weather parameters we want
$NDFDgen->set_weather_parameters(
			'3 Hourly Temperature' => 1,
			'Dewpoint Temperature' => 1,
			'Apparent Temperature' => 1,
			'Wind Speed' => 1,
			'Weather' => 1,
			'Cloud Cover Amount' => 1,
			'Liquid Precipitation Amount' => 1,
			'Relative Humidity' => 1,
			'Minimum Temperature' => 1,
			'Maximum Temperature' => 1,
			'12 Hour Probability of Precipitation' => 1,
			'Wind Direction' => 1 );

#get_params();

#  write out a copy of forecast xml (for debugging/sanity)
my $xml = $NDFDgen->get_forecast_xml();
open(XMLFILE,">$weatherDB/forecast.xml");
print XMLFILE $xml;
close (XMLFILE);

# create the output array of size $num_hours
#  this will be used to generate the plist
for ($i=0; $i< $num_hours; $i++){
	$weather_data[$i] = { Hour => $i };
}	
###### These elements will all be added to the weather_data array in
######             this order:
#  		WeatherConditions (sub-dictionary)
#		Temperature (apparent)
#		DewPoint (temperature)
#		Temp3hour 
#		MinTemp
#		MaxTemp
#		WindSpeed
#		WindDirect
#		CloudCover
#		LiquidPercAmount
#		RelativeHumid
#		PrecipProb

#$weather_data[0]{maxTemp}=55;
#print STDERR "wd = $weather_data[0]{maxTemp}\n";

# setup XML parser
$xp = XML::XPath->new( xml => $xml );

#############################################################
## filling the weather_data array 
##    We will do this in the order of elements listed above 
#############################################################
##########   Weather   ######
print STDERR "parsing weather-conditions\n";
$weather_path="//data/parameters/weather/weather-conditions/value";
$weather_nodeset = $xp->find($weather_path);
@w_node_list = $weather_nodeset->get_nodelist;

# We will construct an  array of hash containing the weather predictions
#  Because of 'additives' we don't know the number of predictions we have yet
$pred_index=0;
foreach $node (@w_node_list){
	$_ = XML::XPath::XMLParser::as_string($node);
	if (/additive/){ # second part of a two parter
		$pred_index--; # roll back the index
		/coverage="(.*)" intensity="(.*)" additive="(.*)" weather-type="(.*)" qualifier="(.*)"/;
		$weather_pred[$pred_index]{coverage2} = $1;  
		$weather_pred[$pred_index]{intensity2} = $2;  
		$weather_pred[$pred_index]{type2} = $2;  
		$weather_pred[$pred_index]{qualifier2} = $4;  
		$pred_index++; # roll it forward again
	} else { # first part, don't know if we have 1 or 2 parts
		/coverage="(.*)" intensity="(.*)" weather-type="(.*)" qualifier="(.*)"/;
		$weather_pred[$pred_index] = { type => $3,
						qualifier => $4,
						intensity => $2,
						coverage => $1 };
		$pred_index++; # increment the index, though we may need to roll back
	}
}
$num_preds = $pred_index;
if ($num_preds==0){
	print STDERR "noaa has failed us, 0 weather predictions\n";
	exit(0);
}
$hours_per_pred = POSIX::ceil($num_hours/$num_preds);
print STDERR "hours per weather prediction: $hours_per_pred\n";

$hour_index=0;
foreach $w (@weather_pred){
	for ($i=0;  $i< $hours_per_pred; $i++ ){
		#print STDERR "hour: $hour_index\n";
		$weather_data[$hour_index]{Hour} = $hour_index;
		foreach $key ( keys %{ $w }){
			#print STDERR "setting weather_d{$key} = ${$w}{$key}\n";
			$weather_data[$hour_index]{WeatherConditions}{$key} = ${$w}{$key};
		}
		$hour_index++;
	}
}

##########   ApparentTemp   ######
$temp_path='//data/parameters/temperature[@type=\'apparent\']/value/text()';
print STDERR "parsing: ApparentTemp...\n";
parseValues( $temp_path, Temperature);

##########   DewPointTemp   ######
$dew_path='//data/parameters/temperature[@type=\'dew point\']/value/text()';
print STDERR "DewPointTemp...\n";
parseValues( $dew_path, DewPoint );

##########   Temp3hour   ######
$temp_path='//data/parameters/temperature[@type=\'hourly\']/value/text()';
print STDERR "Temp3hour...\n";
parseValues( $temp_path, Temp3hour );

##########    MinTemp  ########
$min_path='//data/parameters/temperature[@type=\'minimum\']/value/text()';
print STDERR "minTemp...\n";
parseValues( $min_path, MinTemp );

##########    MaxTemp ########
$max_path='//data/parameters/temperature[@type=\'maximum\']/value/text()';
print STDERR "MaxTemp...\n";
parseValues( $max_path, MaxTemp );

##########   WindSpeed   ######
$windspeed_path='//data/parameters/wind-speed[@type=\'sustained\']/value/text()';
print STDERR "wind Speed..\n";
parseValues( $windspeed_path, WindSpeed );

##########   WindDirect   ######
$winddirect_path='//data/parameters/direction[@type=\'wind\']/value/text()';
print STDERR "wind dir...\n";
parseValues( $winddirect_path, WindDirect );

##########   CloudCover   ######
$cloudcover_path='//data/parameters/cloud-amount[@type=\'total\']/value/text()';
print STDERR "cloud cover...\n";
parseValues( $cloudcover_path, CloudCover );

############ LiquidPercAmount #########
$liquid_path='//data/parameters/precipitation[@type=\'liquid\']/value/text()';
print STDERR "liquid perc...\n";
parseValues( $liquid_path, LiquidPercAmount );

############ RelativeHumid ###########
$humid_path='//data/parameters/humidity[@type=\'relative\']/value/text()';
print STDERR "humidity...\n";
parseValues( $humid_path, RelativeHumid );

############ PrecipProb ###########
$precip_path='//data/parameters/probability-of-precipitation[@type=\'12 hour\']/value/text()';
print STDERR "precip...\n";
parseValues( $precip_path, PrecipProb );

## Generate the plist ---------------------------------------------
open(PLIST,">$weatherDB/$plist_filename");
# header BS
print PLIST '<?xml version="1.0" encoding="UTF-8"?>'."\n";
print PLIST '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'."\n";
print PLIST '<plist version="1.0">'."\n";

### start the outermost dictionary & generate location info
print PLIST "<dict>\n";
print PLIST "\t<key>LastUpdate</key>\n";
print PLIST "\t<integer>".time()."</integer>\n";
print PLIST "\t<key>LocationName</key>\n";
print PLIST "\t<string>$city, $state</string>\n";
print PLIST "\t<key>Coordinates</key>\n";
### coordinates sub-dict
print PLIST "\t<dict>\n";
print PLIST "\t\t<key>latitude</key>\n";
print PLIST "\t\t<real>$latitude</real>\n";
print PLIST "\t\t<key>longitude</key>\n";
print PLIST "\t\t<real>$longitude</real>\n";
print PLIST "\t</dict>\n";
## forecast data
print PLIST "\t<key>HourlyForecasts</key>\n";
print PLIST "\t<array>\n";

# iterate over every hour and make a dict for each
for ($i=0; $i< $num_hours; $i++ ){
	print PLIST "\t\t<dict>\n";
	print PLIST "\t\t\t<key>Hour</key>\n";
	print PLIST "\t\t\t<integer>$i</integer>\n";
	print PLIST "\t\t\t<key>WeatherConditions</key>\n";
	## weather conditions sub-diectionary
	print PLIST "\t\t\t<dict>\n";
	foreach $wkey ( keys %{ $weather_data[$i]{WeatherConditions} }){
		print PLIST "\t\t\t\t<key>$wkey</key>\n";
		print PLIST "\t\t\t\t<string>$weather_data[$i]{WeatherConditions}{$wkey}</string>\n";

	}
	print PLIST "\t\t\t</dict>\n";
	# back to regular params
	print PLIST "\t\t\t<key>Temperature</key>\n";
	print PLIST "\t\t\t<integer>$weather_data[$i]{Temperature}</integer>\n";

	print PLIST "\t\t\t<key>DewPoint</key>\n";
	print PLIST "\t\t\t<integer>$weather_data[$i]{DewPoint}</integer>\n";

	print PLIST "\t\t\t<key>Temp3hour</key>\n";
	print PLIST "\t\t\t<integer>$weather_data[$i]{Temp3hour}</integer>\n";

	print PLIST "\t\t\t<key>MinTemp</key>\n";
	print PLIST "\t\t\t<integer>$weather_data[$i]{MinTemp}</integer>\n";

	print PLIST "\t\t\t<key>MaxTemp</key>\n";
	print PLIST "\t\t\t<integer>$weather_data[$i]{MaxTemp}</integer>\n";

	print PLIST "\t\t\t<key>WindSpeed</key>\n";
	print PLIST "\t\t\t<integer>$weather_data[$i]{WindSpeed}</integer>\n";

	print PLIST "\t\t\t<key>WindDirect</key>\n";
	print PLIST "\t\t\t<integer>$weather_data[$i]{WindDirect}</integer>\n";

	print PLIST "\t\t\t<key>CloudCover</key>\n";
	print PLIST "\t\t\t<integer>$weather_data[$i]{CloudCover}</integer>\n";

	print PLIST "\t\t\t<key>WindDirect</key>\n";
	print PLIST "\t\t\t<integer>$weather_data[$i]{WindDirect}</integer>\n";

	print PLIST "\t\t\t<key>LiquidPercAmount</key>\n";
	print PLIST "\t\t\t<real>$weather_data[$i]{LiquidPercAmount}</real>\n";

	print PLIST "\t\t\t<key>RelativeHumid</key>\n";
	print PLIST "\t\t\t<integer>$weather_data[$i]{RelativeHumid}</integer>\n";

	print PLIST "\t\t\t<key>PrecipProb</key>\n";
	print PLIST "\t\t\t<integer>$weather_data[$i]{PrecipProb}</integer>\n";

	print PLIST "\t\t</dict>\n";
}
print PLIST "\t</array>\n";
print PLIST "</dict>\n</plist>\n";
close(PLIST);

# write the filename to STDOUT
print $plist_filename;

########################------------ functions --------------------

# args: xmlpath hashID
sub parseValues {
	#print STDERR "parseValues args: $_[0] $_[1]\n"; 
	my $xml_path = $_[0];
	my $hash_ID = $_[1];
	my $nodeset = $xp->find($xml_path);
	my @node_list = $nodeset->get_nodelist;
	my $num_preds = $#node_list+1;
	if ($num_preds == 0){
		print STDERR "No $hash_ID predictions in this forecast window\n";
		return;
	}
	my $hours_per_pred = POSIX::ceil($num_hours/$num_preds);
	#print STDERR "hours per prediction: $hours_per_pred\n";
	my $hour_index=0;
	foreach $node (@node_list){
		my $weatherVal = XML::XPath::XMLParser::as_string($node);
		for (my $i=0; $i< $hours_per_pred; $i++){
			#print STDERR "weatherVal = $weatherVal\n";
			$weather_data[$hour_index]{$hash_ID} = $weatherVal; 
			$hour_index++;
		}
	}

}

sub get_params {
	@weather_parameters = $NDFDgen->get_available_weather_parameters();
	foreach $w (@weather_parameters){
		print STDERR "w= $w\n";
	}
}
