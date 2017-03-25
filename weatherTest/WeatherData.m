//
//  WeatherData.m
//  weatherTest
//
//  Created by Bjorn Chambless on 6/11/13.
//  Copyright (c) 2013 Bjorn Chambless. All rights reserved.
//

#import "WeatherData.h"
#import "sqlite3.h"

NSString *NOTIF_WEATHER_DATA_READY = @"NOTIF_WEATHER_DATA_READY";

@interface WeatherData ()

@property (nonatomic,assign) char *cityNameReq;
@property (nonatomic,assign) char *stateNameReq;
@property (nonatomic,assign) int numHoursReq;
@property (nonatomic,assign) double latitudeReq;
@property (nonatomic,assign) double longitudeReq;
@property (nonatomic,assign) BOOL dataReady;

@property (nonatomic,retain) NSDictionary *weatherForecast;

-(void) dataReadThread;

-(void) requestWeatherDataFromLat:(float)lat
                          andLong:(float)lon
                      forNumHours:(int)hours
                          andCity:(char*)city
                         andState:(char*)state;

@end


@implementation WeatherData

-(id) init {
    self = [super init];
    if (self) {
        self.dataReady = NO;
    }
    return self;
}

#define MAX_PATH_LEN 512
#define MAX_QUERY_LEN 512
#define MAX_QUERY_RESULT 1024
#define MAX_STR_LEN 100

// static global so they last long enough to get returned
static char city[MAX_STR_LEN];
static char state[MAX_STR_LEN];

-(NSDictionary*) requestWeatherDataFromZipcode:(int)zip andNumHours:(int)hours {
    sqlite3 *handle;
    int retval;
    char q_str[MAX_QUERY_LEN];
    sqlite3_stmt *stmt;
    const char *pos;
    double latit;
    double longit;
    BOOL fauxFlag;
    char plistFile[MAX_STR_LEN]; // tmp pointer to file containing weather data
    NSDictionary *returnDict; // this will return with some geo info
    
    // find our zipcode database;
    NSBundle *mainBundle = [NSBundle mainBundle];    
    NSString *dbPath = [mainBundle pathForResource:WEATHER_DB_FILENAME ofType:WEATHER_DB_TYPE];
    NSLog(@"DB file path= %@",dbPath);
    
    fprintf(stderr,"opening dbfile...\n");
    
    retval = sqlite3_open([dbPath UTF8String],&handle);
    if (retval != SQLITE_OK) {
        fprintf(stderr,"failure opening zip->coords DB\n");
        exit(0);
    }
    sprintf(q_str, "SELECT fauxflag, plist, city, state, latitude, longitude FROM %s WHERE zip=%d",ZIP_TABLE,zip);
    fprintf(stderr,"query = %s\n",q_str);
    retval = sqlite3_prepare_v2(handle, q_str, MAX_QUERY_RESULT, &stmt, &pos);
    if (retval != SQLITE_OK) {
        fprintf(stderr,"sqlite prepare failed\n");
        exit(0);
    }
    retval = sqlite3_step(stmt);
    if (retval == SQLITE_DONE) { // no such zipcode found
        _weatherForecast = nil;
        sqlite3_finalize(stmt);
        sqlite3_close(handle);
        return nil;
    }
    // setup the return dictionary
    sprintf(city, "%s",sqlite3_column_text(stmt, 2));
    sprintf(state,"%s",sqlite3_column_text(stmt, 3));
    latit = sqlite3_column_double(stmt, 4);
    longit = sqlite3_column_double(stmt, 5);
    returnDict = @{ @"latitude": @(latit),
                    @"longitude": @(longit),
                    @"city": @(city),
                    @"state": @(state),
                    @"numHours": @(hours) };
    
    // check if the location is real or imaginary
    fauxFlag = (BOOL)sqlite3_column_int(stmt, 0);
    
    if (fauxFlag){ // this is a "canned" location, we will read a static plist file
        strcpy(plistFile,(char*)sqlite3_column_text(stmt, 1));
        NSString *pfile = [NSString stringWithUTF8String:strtok(plistFile, ".")];
        NSString *ptype = [NSString stringWithUTF8String:strtok(plistFile, ".")];
        fprintf(stderr,"reading faux weather forecast from file: %s\n",plistFile);
        NSString *plistPath = [mainBundle pathForResource:pfile ofType:ptype];
        NSLog(@"found at path %@",plistPath);
        _weatherForecast = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        // and we're done
        self.dataReady = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_WEATHER_DATA_READY object:self];
        return returnDict;
    } else { //  we need to go ask NOAA
        [self requestWeatherDataFromLat:latit
                                andLong:longit
                            forNumHours:hours
                                andCity:city
                               andState:state];
    }
    sqlite3_finalize(stmt);
    sqlite3_close(handle);
    return returnDict;
}

    

-(void) requestWeatherDataFromLat:(float)lat
                            andLong:(float)lon
                       forNumHours:(int)hours
                          andCity:(char*)city
                         andState:(char*)state {
    self.latitudeReq = lat;
    self.longitudeReq = lon;
    self.numHoursReq = hours;
    self.cityNameReq = city;
    self.stateNameReq = state;
    
    [NSThread detachNewThreadSelector:@selector(dataReadThread) toTarget:self withObject:nil];
}


-(NSDictionary*) readWeatherData {
    if (self.dataReady) {
        return self.weatherForecast;
    } else {
        return nil;
    }
}

#define DATA_SIZE 1024
#define COMMAND_SIZE 1024

-(void) dataReadThread {
    FILE *pf;
    char command[COMMAND_SIZE];
    char forecast_filename[DATA_SIZE];
    char data_file_path[DATA_SIZE];
    //char *perlScriptPath = WEATHER_DB_PATH;
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *perlScriptPath = [mainBundle pathForResource:WEATHER_SCRIPT ofType:WEATHER_SCRIPT_TYPE];
    NSLog(@"found perl script at: %@",perlScriptPath);
    sprintf(command, "%s %.2f %.2f %d \"%s\" %s %s",[perlScriptPath UTF8String],
                                            self.latitudeReq,
                                            self.longitudeReq,
                                            self.numHoursReq,
                                            self.cityNameReq,
                                            self.stateNameReq,
                                            [[mainBundle resourcePath] UTF8String]);
    //sprintf(command, "%s/%s %.2f %.2f %d %s %s", perlScriptPath, WEATHER_SCRIPT,self.latitudeReq,self.longitudeReq,self.numHoursReq,self.cityNameReq,self.stateNameReq);
    // debug output
    fprintf(stderr, "command= %s\n",command);
    
    pf = popen(command, "r");
    fgets(forecast_filename,DATA_SIZE,pf);
    pclose(pf);
    sprintf(data_file_path,"%s/%s",[[mainBundle resourcePath] UTF8String],forecast_filename);
    fprintf(stderr,"plist datafile: %s\n",data_file_path);
    self.weatherForecast = [NSDictionary dictionaryWithContentsOfFile:@(data_file_path)];
    self.dataReady = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_WEATHER_DATA_READY object:self];
}


@end
