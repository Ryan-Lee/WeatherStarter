//
//  WTTableViewController.m
//  Weather
//
//  Created by Scott on 26/01/2013.
//  Copyright (c) 2013 Scott Sherwood. All rights reserved.
//

#import "WTTableViewController.h"
#import "WeatherAnimationViewController.h"
#import "NSDictionary+weather.h"
#import "NSDictionary+weather_package.h"
#import "WeatherHTTPClient.h"

static NSString *const BaseURLString = @"http://www.raywenderlich.com/downloads/weather_sample/";

@interface WTTableViewController ()

@property(strong) NSDictionary *weather;

@property(strong) NSMutableDictionary *xmlWeather; //package containing the complete response
@property(strong) NSMutableDictionary *currentDictionary; //current section being parsed
@property(strong) NSString *previousElementName;
@property(strong) NSString *elementName;
@property(strong) NSMutableString *outstring;

@end

@implementation WTTableViewController



- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.toolbarHidden = NO;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    self.manager = [[CLLocationManager alloc] init];
    self.manager.delegate = self;
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"WeatherDetailSegue"]){
        UITableViewCell *cell = (UITableViewCell *)sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        
        WeatherAnimationViewController *wac = (WeatherAnimationViewController *)segue.destinationViewController;
        
        NSDictionary *w;
        switch (indexPath.section) {
            case 0:{
                w = self.weather.currentCondition;
                break;
            }
            case 1:{
                w = [[self.weather upcomingWeather] objectAtIndex:indexPath.row];
                break;
            }
            default:{
                break;
            }
        }
        
        wac.weatherDictionary = w;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    
    //if the location is more than 5 minutes old ignore
    if([newLocation.timestamp timeIntervalSinceNow]< 300){
        [self.manager stopUpdatingLocation];
        
        WeatherHTTPClient *client = [WeatherHTTPClient sharedWeatherHTTPClient];
        client.delegate = self;
        [client updateWeatherAtLocation:newLocation forNumberOfDays:5];
    }
}
-(void)weatherHTTPClient:(WeatherHTTPClient *)client didUpdateWithWeather:(id)aWeather{
    self.weather = aWeather;
    self.title = @"API Updated";
    [self.tableView reloadData];
}

-(void)weatherHTTPClient:(WeatherHTTPClient *)client didFailWithError:(NSError *)error{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error Retrieving Weather"
                                                 message:[NSString stringWithFormat:@"%@",error]
                                                delegate:nil
                                       cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av show];
}

#pragma mark - UIActionSheetDelegate
	
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    // 1
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:BaseURLString]];
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:@"json" forKey:@"format"];
    
    // 2
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    [client registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [client setDefaultHeader:@"Accept" value:@"application/json"];
    
    // 3
    if (buttonIndex==0) {
        [client postPath:@"weather.php"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     self.weather = responseObject;
                     self.title = @"HTTP POST";
                     [self.tableView reloadData];
                 }
                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error Retrieving Weather"
                                                                  message:[NSString stringWithFormat:@"%@",error]
                                                                 delegate:nil
                                                        cancelButtonTitle:@"OK" otherButtonTitles:nil];
                     [av show];
                     
                 }
         ];
    }
    // 4
    else if (buttonIndex==1) {
        [client getPath:@"weather.php"
             parameters:parameters
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    self.weather = responseObject;
                    self.title = @"HTTP GET";
                    [self.tableView reloadData];
                }
                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error Retrieving Weather"
                                                                 message:[NSString stringWithFormat:@"%@",error]
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [av show];
                    
                }
         ];
    }
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict  {
    self.previousElementName = self.elementName;
    
    if (qName) {
        self.elementName = qName;
    }
    
    if([qName isEqualToString:@"current_condition"]){
        self.currentDictionary = [NSMutableDictionary dictionary];
    }
    else if([qName isEqualToString:@"weather"]){
        self.currentDictionary = [NSMutableDictionary dictionary];
    }
    else if([qName isEqualToString:@"request"]){
        self.currentDictionary = [NSMutableDictionary dictionary];
    }
    
    self.outstring = [NSMutableString string];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (!self.elementName){
        return;
    }
    
    [self.outstring appendFormat:@"%@", string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    // 1
    if([qName isEqualToString:@"current_condition"] ||
       [qName isEqualToString:@"request"]){
        [self.xmlWeather setObject:[NSArray arrayWithObject:self.currentDictionary] forKey:qName];
        self.currentDictionary = nil;
    }
    // 2
    else if([qName isEqualToString:@"weather"]){
        
        // Initalise the list of weather items if it dosnt exist
        NSMutableArray *array = [self.xmlWeather objectForKey:@"weather"];
        if(!array)
            array = [NSMutableArray array];
        
        [array addObject:self.currentDictionary];
        [self.xmlWeather setObject:array forKey:@"weather"];
        
        self.currentDictionary = nil;
    }
    // 3
    else if([qName isEqualToString:@"value"]){
        //Ignore value tags they only appear in the two conditions below
    }
    // 4
    else if([qName isEqualToString:@"weatherDesc"] ||
            [qName isEqualToString:@"weatherIconUrl"]){
        [self.currentDictionary setObject:[NSArray arrayWithObject:[NSDictionary dictionaryWithObject:self.outstring forKey:@"value"]] forKey:qName];
    }
    // 5
    else {
        [self.currentDictionary setObject:self.outstring forKey:qName];
    }
    
	self.elementName = nil;
}

-(void) parserDidEndDocument:(NSXMLParser *)parser {
    self.weather = [NSDictionary dictionaryWithObject:self.xmlWeather forKey:@"data"];
    self.title = @"XML Retrieved";
    [self.tableView reloadData];
}

#pragma mark Actions

- (IBAction)clear:(id)sender {
    self.title = @"";
    self.weather = nil;
    [self.tableView reloadData];
}

- (IBAction)jsonTapped:(id)sender
{
    NSString *weatherUrl = [NSString stringWithFormat:@"%@weather.php?format=json", BaseURLString];
    NSURL *url = [NSURL URLWithString:weatherUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFJSONRequestOperation *operation =
    [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                        self.weather  = (NSDictionary *)JSON;
                                                        self.title = @"JSON Retrieved";
                                                        [self.tableView reloadData];
                                                    }
                                                    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error Retrieving Weather"
                                                                                                     message:[NSString stringWithFormat:@"%@",error]
                                                                                                    delegate:nil
                                                                                           cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                                        [av show];
                                                    }];
    
    [operation start];
}

- (IBAction)plistTapped:(id)sender
{
    NSString *weatherUrl = [NSString stringWithFormat:@"%@weather.php?format=plist",BaseURLString];
    NSURL *url = [NSURL URLWithString:weatherUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFPropertyListRequestOperation *operation =
    [AFPropertyListRequestOperation propertyListRequestOperationWithRequest:request
                                                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id propertyList) {
                                                                        self.weather  = (NSDictionary *)propertyList;
                                                                        self.title = @"PLIST Retrieved";
                                                                        [self.tableView reloadData];
                                                                    }
                                                                    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id propertyList) {
                                                                        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error Retrieving Weather"
                                                                                                                     message:[NSString stringWithFormat:@"%@",error]
                                                                                                                    delegate:nil
                                                                                                           cancelButtonTitle:@"OK"
                                                                                                           otherButtonTitles:nil];
                                                                        [av show];
                                                                    }];
    
    [operation start];
}

- (IBAction)xmlTapped:(id)sender
{
    NSString *weatherUrl = [NSString stringWithFormat:@"%@weather.php?format=xml",BaseURLString];
    NSURL *url = [NSURL URLWithString:weatherUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    AFXMLRequestOperation *operation =
    [AFXMLRequestOperation XMLParserRequestOperationWithRequest:request
                                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSXMLParser *XMLParser) {
                                                            self.xmlWeather = [NSMutableDictionary dictionary];
                                                            XMLParser.delegate = self;
                                                            [XMLParser setShouldProcessNamespaces:YES];
                                                            [XMLParser parse];
                                                            NSLog(@"%@" , [response allHeaderFields]) ;
                                                        }
                                                        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSXMLParser *XMLParser) {
                                                            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error Retrieving Weather"
                                                                                                         message:[NSString stringWithFormat:@"%@",error]
                                                                                                        delegate:nil
                                                                                               cancelButtonTitle:@"OK"
                                                                                               otherButtonTitles:nil];
                                                            [av show];
                                                        }];
    
    [operation start];
}

- (IBAction)httpClientTapped:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"AFHTTPClient" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"HTTP POST",@"HTTP GET", nil];
    [actionSheet showFromBarButtonItem:sender animated:YES];

}

- (IBAction)apiTapped:(id)sender
{
    [self.manager startUpdatingLocation];

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(!self.weather)
        return 0;
    
    switch (section) {
        case 0:{
            return 1;
        }
        case 1:{
            NSArray *upcomingWeather = [self.weather upcomingWeather];
            return [upcomingWeather count];
        }
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    // Configure the cell...
    static NSString *CellIdentifier = @"WeatherCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    NSDictionary *daysWeather;
    
    switch (indexPath.section) {
        case 0:{
            daysWeather = [self.weather currentCondition];
            break;
        }
        case 1:{
            NSArray *upcomingWeather = [self.weather upcomingWeather];
            daysWeather = [upcomingWeather objectAtIndex:indexPath.row];
        }
        default:
            break;
    }
    
    cell.textLabel.text = [daysWeather weatherDescription];
    
    // maybe some code will be added here later...
    __weak UITableViewCell *weakCell = cell;
    
    [cell.imageView setImageWithURLRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:daysWeather.weatherIconURL]]
                          placeholderImage:[UIImage imageNamed:@"placeholder.png"]
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image){
                                       weakCell.imageView.image = image;
                                       
                                       //only required if no placeholder is set to force the imageview on the cell to be laid out to house the new image.
                                       //if(weakCell.imageView.frame.size.height==0 || weakCell.imageView.frame.size.width==0 ){
                                       [weakCell setNeedsLayout];
                                       //}
                                   }
                                   failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error){
                                       
                                   }];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
}

@end
