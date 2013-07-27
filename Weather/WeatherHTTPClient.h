//
//  WeatherHTTPClient.h
//  Weather
//
//  Created by Ryan on 13-7-25.
//  Copyright (c) 2013年 Scott Sherwood. All rights reserved.
//

#import "AFHTTPClient.h"

@protocol WeatherHttpClientDelegate;

@interface WeatherHTTPClient : AFHTTPClient

@property(weak) id delegate;

+ (WeatherHTTPClient *)sharedWeatherHTTPClient;
- (id)initWithBaseURL:(NSURL *)url;
- (void)updateWeatherAtLocation:(CLLocation *)location forNumberOfDays:(int)number;

@end

@protocol WeatherHttpClientDelegate
-(void)weatherHTTPClient:(WeatherHTTPClient *)client didUpdateWithWeather:(id)weather;
-(void)weatherHTTPClient:(WeatherHTTPClient *)client didFailWithError:(NSError *)error;
@end