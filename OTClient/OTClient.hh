//
//  OTClient.hh
//  OTClient-iOS
//
//  Created by happywarrior on 1/13/13.
//  Copyright (c) 2013 happywarrior. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTClient : NSObject

@property (nonatomic, readonly) NSInteger assetTypeCount;
@property (nonatomic, readonly) NSInteger serverCount;

+ (id)sharedInstance;

- (BOOL)addAssetContract:(NSString *)contract;
- (BOOL)addServerContract:(NSString *)contract;

- (NSString *)assetTypeID:(NSUInteger)index;
- (NSString *)assetTypeContract:(NSString *)assetTypeID;

- (NSString *)serverID:(NSUInteger)index;
- (NSString *)serverContract:(NSString *)serverID;

// more APIs coming soon!

@end
