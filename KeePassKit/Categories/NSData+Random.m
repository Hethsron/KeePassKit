//
//  NSData+Random.m
//  MacPass
//
//  Created by Michael Starke on 24.06.13.
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

#import "NSData+Random.h"
#import <Security/SecRandom.h>

@implementation NSData (Random)

+ (NSData *)dataWithRandomBytes:(NSUInteger)length {
  uint8_t *bytes = malloc(sizeof(uint8_t) * length);
  int ret = SecRandomCopyBytes(kSecRandomDefault, length, bytes);
  if(ret != 0) {
    free(bytes);
    return nil;
  }
  return [NSData dataWithBytesNoCopy:bytes length:length freeWhenDone:YES];
}

@end
