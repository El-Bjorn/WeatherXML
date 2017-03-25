#!/usr/bin/perl -w  

use XML::XPath;
use DateTime::Format::XSD;
use Weather::NWS::NDFDgen;

#print "arg1= $ARGV[0]\n";
$latitude = $ARGV[0];
#print "arg2= $ARGV[1]\n";
$longitude = $ARGV[1];


my $NDFDgen = Weather::NWS::NDFDgen->new();
$NDFDgen->set_latitude($latitude);
$NDFDgen->set_longitude($longitude);
$NDFDgen->set_product('Time-Series');


my $dt = DateTime->now();
$start_time = DateTime::Format::XSD->format_datetime($dt);
$NDFDgen->set_start_time($start_time);

$dt->add( days => 1 );
my $end_time = DateTime::Format::XSD->format_datetime($dt);
$NDFDgen->set_end_time($end_time);

$NDFDgen->set_weather_parameters(
			'3 Hourly Temperature' => 0,
			'Dewpoint Temperature' => 0,
			'Apparent Temperature' => 0,
			'Weather' => 0,
			'Cloud Cover Amount' => 0,
			'Liquid Precipitation Amount' => 0,
			'Relative Humidity' => 0,
			'Minimum Temperature' => 0,
			'Maximum Temperature' => 1,
			'Wind Direction' => 0 );

my $xml = $NDFDgen->get_forecast_xml();
#open(XMLFILE,'>forecast.xml');
#print XMLFILE $xml;
#close (XMLFILE);
my $xp = XML::XPath->new( xml => $xml );
my $temp_path="//data/parameters/temperature/value/text()";
my $temp_nodeset = $xp->find($temp_path);
my @t_node_list = $temp_nodeset->get_nodelist;
$max_temp = XML::XPath::XMLParser::as_string($t_node_list[0]); 
print "$max_temp";

