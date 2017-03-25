//
//  WTAppDelegate.m
//  weatherTest
//
//  Created by Bjorn Chambless on 6/9/13.
//  Copyright (c) 2013 Bjorn Chambless. All rights reserved.
//

#import "WTAppDelegate.h"
#import "WeatherData.h"

WeatherData *w;
extern NSString *NOTIF_WEATHER_DATA_READY;

@implementation WTAppDelegate

@synthesize latCell,longCell,zipCell,tempField;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}

-(IBAction)get_temp:(id)sender {
    NSDictionary *retDict;
    w = [[WeatherData alloc] init];
    fprintf(stderr,"asking for weather for zipcode: %d\n",zipCell.intValue);
        
    retDict = [w requestWeatherDataFromZipcode:zipCell.intValue andNumHours:36];
    if (!retDict) {
        fprintf(stderr,"No such zipcode\n");
        tempField.stringValue = @"Bad ZIP";
        return;
    }
    NSLog(@"we requested: %@",retDict);
    
    //[w requestWeatherDataFromLat:latCell.floatValue andLong:longCell.floatValue];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readTempData) name:NOTIF_WEATHER_DATA_READY object:nil];    
}

-(void) readTempData {
    NSDictionary *theWeather = [w readWeatherData];
    //float theTemp = [w readWeatherData];
    //fprintf(stderr,"-readTempData temp=%.2f\n",theTemp);
    tempField.stringValue = @"Done";
    NSLog(@"the weather: %@",theWeather);
}


@end
