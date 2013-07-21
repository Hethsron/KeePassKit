//
//  NSUUID+KeePassKit.m
//  KeePassKit
//
//  Created by Michael Starke on 25.06.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "NSUUID+KeePassKit.h"
#import "NSMutableData+Base64.h"
#import "NSString+Base64.h"

static NSUUID *aesUUID = nil;

@implementation NSUUID (KeePassKit)

+ (NSUUID *)nullUUID {
  return [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"];
}

+ (NSUUID *)AESUUID {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    aesUUID = [[NSUUID alloc] initWithUUIDString:@"31C1F2E6-BF71-4350-BE58-05216AFC5AFF"];
  });
  return aesUUID;
}

+ (NSUUID *)uuidWithEncodedString:(NSString *)string {
  return [[NSUUID alloc] initWithEncodedUUIDString:string];
}

- (id)initWithEncodedUUIDString:(NSString *)string {
  NSString *uuidString = [string base64DecodedString];
  self = [self initWithUUIDString:uuidString];
  return self;
}

- (id)initWithData:(NSData *)data {
  unsigned char uuidData[16];
  [data getBytes:&uuidData length:16];
  self = [self initWithUUIDBytes:uuidData];
  return self;
}

- (NSString *)encodedString {
  NSData *data = [NSMutableData mutableDataWithBase64EncodedData:[self getUUIDData]];
  return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSData *)getUUIDData {
  uint8_t *bytes = NULL;
  [self getUUIDBytes:bytes];
  
  return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

@end