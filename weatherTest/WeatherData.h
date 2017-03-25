//
//  WeatherData.h
//  weatherTest
//
//  Created by Bjorn Chambless on 6/11/13.
//  Copyright (c) 2013 Bjorn Chambless. All rights reserved.
//

#import <Foundation/Foundation.h>

/* weather db file and table (don't mess with this stuff) */
#define WEATHER_SCRIPT @"getWeather"
#define WEATHER_SCRIPT_TYPE @"pl"
#define WEATHER_DB_FILENAME @"zipToCoords"
#define WEATHER_DB_TYPE @"db"
#define ZIP_TABLE "zipcodes"

@interface WeatherData : NSObject

-(NSDictionary*) requestWeatherDataFromZipcode:(int)zip andNumHours:(int)hours;

-(NSDictionary*) readWeatherData;


@end
