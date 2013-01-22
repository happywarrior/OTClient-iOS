//
//  OTClient.mm
//  OTClient-iOS
//
//  Created by happywarrior on 1/13/13.
//  Copyright (c) 2013 happywarrior. All rights reserved.
//

#import "OTClient.hh"

#include <OTAPI.h>
#include <OT_ME.h>
#include <OTAsymmetricKey.h>
#include <OTEnvelope.h>

class OTClient_OTCallback : public OTCallback {
    
public:
    OTClient_OTCallback() {};
    virtual ~OTClient_OTCallback() {};
    
    // generates a random password which is used to create a master key that is stored on the keyring
    // use_system_keyring must be enabled so a new master key isn't generated on each request
    virtual void runOne(char const *szDisplay, OTPassword &theOutput)
    {
        theOutput.randomizePassword();
    };
    
    virtual void runTwo(char const *szDisplay, OTPassword &theOutput)
    {
        this->runOne(szDisplay, theOutput);
    };
};


@interface OTClient()

@property (nonatomic, readonly) OT_ME *me;

@end

@implementation OTClient

+ (id)sharedInstance
{
    static OTClient *shared = nil;
    static dispatch_once_t onceToken = 0;
    
    dispatch_once(&onceToken, ^{
        NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    
        // remove pid file
        [NSFileManager.defaultManager removeItemAtPath:[docPath stringByAppendingPathComponent:@"client_data/ot.pid"]
         error:nil];

        // copy config files from app bundle to ~/Documents
        for (NSString *srcPath in [NSBundle.mainBundle pathsForResourcesOfType:@"cfg" inDirectory:nil]) {
            NSString *dstPath = [docPath stringByAppendingPathComponent:[srcPath lastPathComponent]];
            
            if (! [NSFileManager.defaultManager fileExistsAtPath:dstPath]) {
                [NSFileManager.defaultManager copyItemAtPath:srcPath toPath:dstPath error:nil];
            }
        }
        
        // copy scripts from app bundle to ~/Documents/lib/opentxs
        NSString *scriptPath = [docPath stringByAppendingPathComponent:@"lib/opentxs"];
        
        [NSFileManager.defaultManager createDirectoryAtPath:scriptPath withIntermediateDirectories:YES attributes:nil
         error:nil];

        for (NSString *srcPath in [NSBundle.mainBundle pathsForResourcesOfType:@"ot" inDirectory:nil]) {
            NSString *dstPath = [scriptPath stringByAppendingPathComponent:[srcPath lastPathComponent]];
            
            if (! [NSFileManager.defaultManager fileExistsAtPath:dstPath]) {
                [NSFileManager.defaultManager copyItemAtPath:srcPath toPath:dstPath error:nil];
            }
        }

        // set password callback
        OTCaller *caller = new OTCaller();
        caller->setCallback(new OTClient_OTCallback());
        OT_API_Set_PasswordCallback(*caller);

        // ot initialization
        OTAPI_Wrap::AppInit();
        OTAPI_Wrap::It();
        
        OTMasterKey::It()->UseSystemKeyring(); // OTClient_OTCallback requires a keyring
        OTAPI_Wrap::LoadWallet();
        
        shared = [[self alloc] init];
        
        NSMutableSet *serverContracts = [NSMutableSet set], *assetContracts = [NSMutableSet set];
        
        for (int i = 0; i < [shared serverCount]; i++) {
            [serverContracts addObject:[shared serverContract:[shared serverID:i]]];
        }
        
        for (int i = 0; i < [shared assetTypeCount]; i++) {
            [assetContracts addObject:[shared assetTypeContract:[shared assetTypeID:i]]];
        }
        
        // load contracts from the app bundle
        NSArray *contracts = [NSBundle.mainBundle pathsForResourcesOfType:@"otc" inDirectory:nil];
        
        for (NSString *path in contracts) {
            NSString *otc = [[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil]
                             stringByTrimmingCharactersInSet:[NSCharacterSet
                                                              characterSetWithCharactersInString:@" \t\f\v\n\r"]];
            
            if (! [serverContracts containsObject:otc] && ! [assetContracts containsObject:otc]) {
                if ([otc rangeOfString:@"<notaryProviderContract"].location != NSNotFound) {
                    [shared addServerContract:otc];
                }
                else if ([otc rangeOfString:@"<digitalAssetContract"].location != NSNotFound) {
                    [shared addAssetContract:otc];
                }
            }
        }
    });

    return shared;
}

- (id)init
{
    if (! (self = [super init])) return nil;
    
    _me = new OT_ME();
    
    return self;
}

- (NSInteger)serverCount
{
    return OTAPI_Wrap::GetServerCount();
}

- (NSString *)serverID:(NSUInteger)index
{
    return [NSString stringWithUTF8String:OTAPI_Wrap::GetServer_ID(index).c_str()];
}

- (NSString *)serverContract:(NSString *)serverID
{
    return [NSString stringWithUTF8String:OTAPI_Wrap::GetServer_Contract(serverID.UTF8String).c_str()];
}

- (NSInteger)assetTypeCount
{
    return OTAPI_Wrap::GetAssetTypeCount();
}

- (NSString *)assetTypeID:(NSUInteger)index
{
    return [NSString stringWithUTF8String:OTAPI_Wrap::GetAssetType_ID(index).c_str()];
}

- (NSString *)assetTypeContract:(NSString *)assetTypeID
{
    return [NSString stringWithUTF8String:OTAPI_Wrap::GetAssetType_Contract(assetTypeID.UTF8String).c_str()];
}

- (BOOL)addServerContract:(NSString *)contract
{
    return OTAPI_Wrap::AddServerContract(contract.UTF8String);
}

- (BOOL)addAssetContract:(NSString *)contract
{
    return OTAPI_Wrap::AddAssetContract(contract.UTF8String);
}

- (void)dealloc
{    
    OTAPI_Wrap::AppCleanup();
}

@end
