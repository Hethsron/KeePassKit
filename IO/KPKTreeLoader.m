//
//  KPKParser.m
//  KeePassKit
//
//  Created by Michael Starke on 12.07.13.
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


#import "KPKTreeLoader.h"
#import "KPKTree.h"
#import "KPKFormat.h"
#import "KPKPassword.h"
#import "KPKXmlTreeReader.h"
#import "KPKBinaryTreeReader.h"
#import "KPKHeaderFields.h"
#import "KPKErrors.h"

#import "NSUUID+KeePassKit.h"
#import "KPKChipherInformation.h"
#import "NSData+CommonCrypto.h"
#import "NSData+HashedData.h"
#import "NSData+Gzip.h"

#import "KdbPassword.h"

#import "DDXML.h"

@interface KPKTreeLoader () {
@private
  DDXMLDocument *_document;
  NSData *_data;
  KPKVersion _version;
  KPKChipherInformation *_chipherInfo;
  KPKPassword *_password;
}

@end

@implementation KPKTreeLoader

- (id)initWithData:(NSData *)data password:(KPKPassword *)password {
  self = [super init];
  if(self) {
    _data = data;
    _password = password;
  }
  return self;
}

- (KPKTree *)loadTree:(NSError **)error {
  KPKFormat *format = [KPKFormat sharedFormat];
  _version = [format databaseVersionForData:_data];
  
  if(_version == KPKVersion1) {
    NSData *data = [self _decryptVersion1Data];
    KPKBinaryTreeReader *treeReader = [[KPKBinaryTreeReader alloc] initWithData:data];
    return [treeReader tree];
  }
  if(_version == KPKVersion2) {
    NSData *data = [self _decryptVersion2Data:error];
    if(!data) {
      return nil;
    }
    KPKXmlTreeReader *treeReader = [[KPKXmlTreeReader alloc] initWithData:data];
    return [treeReader tree];
  }
  if(error != NULL) {
    *error = KPKCreateError(KPKErrorUnknownFileFormat, @"ERROR_UNKOWN_FILE_FORMAT", "");
  }
  return nil;
}

- (NSData *)_decryptVersion1Data {
  return nil;
}

- (NSData *)_decryptVersion2Data:(NSError **)error {
  _chipherInfo = [[KPKChipherInformation alloc] initWithData:_data error:error];
  if(!_chipherInfo) {
    return nil;
  }
  //CCCryptorCreate(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, key.bytes, kCCKeySizeAES256, iv.bytes, &cryptorRef);
  NSData *keyData = [_password finalDataForVersion:_version masterSeed:_chipherInfo.masterSeed transformSeed:_chipherInfo.transformSeed rounds:_chipherInfo.rounds];
  NSData *aesDecrypted = [[_chipherInfo dataWithoutHeader] decryptedDataUsingAlgorithm:kCCAlgorithmAES128
                                                                                   key:keyData
                                                                  initializationVector:_chipherInfo.encryptionIV
                                                                               options:kCCOptionPKCS7Padding
                                                                                 error:NULL];
  
  NSData *startBytes = [aesDecrypted subdataWithRange:NSMakeRange(0, 32)];
  if(![_chipherInfo.streamStartBytes isEqualToData:startBytes]) {
    if(error != NULL) {
      *error = KPKCreateError(KPKErrorKDBXIntegrityCheckFaild, @"ERROR_INTEGRITY_CHECK_FAILED", "");
    }
    return nil;
  }
  NSData *unhashedData = [[aesDecrypted subdataWithRange:NSMakeRange(32, [aesDecrypted length] - 32)] unhashedData];
  if(_chipherInfo.compressionAlgorithm == KPKCompressionGzip) {
    unhashedData = [unhashedData gzipInflate];
  }
  
  if(!unhashedData) {
    if(error != NULL) {
      *error = KPKCreateError(KPKErrorKDBXIntegrityCheckFaild, @"ERROR_INTEGRITY_CHECK_FAILED", "");
    }
    return nil;
  }
  
  //  // Create the AES input stream
  //  NSData *key = [kdbPassword createFinalKeyForVersion:4 masterSeed:masterSeed transformSeed:transformSeed rounds:rounds];
  //  AesInputStream *aesInputStream = [[AesInputStream alloc] initWithInputStream:inputStream key:key iv:encryptionIv];
  //
  //  // Verify the stream start bytes match
  //  NSData *startBytes = [aesInputStream readData:32];
  //  if (![startBytes isEqual:streamStartBytes]) {
  //    aesInputStream = nil;
  //    @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to decrypt" userInfo:nil];
  //  }
  //
  //  // Create the hashed input stream and swap in the compression input stream if compressed
  //  InputStream *stream = [[HashedInputStream alloc] initWithInputStream:aesInputStream];
  //  if (compressionAlgorithm == COMPRESSION_GZIP) {
  //    stream = [[GZipInputStream alloc] initWithInputStream:stream];
  //  }
  //
  //  // Create the CRS Algorithm
  //  RandomStream *randomStream = nil;
  //  if (randomStreamID == CSR_SALSA20) {
  //    randomStream = [[Salsa20RandomStream alloc] init:protectedStreamKey];
  //  } else if (randomStreamID == CSR_ARC4VARIANT) {
  //    randomStream = [[Arc4RandomStream alloc] init:protectedStreamKey];
  //  } else {
  //    @throw [NSException exceptionWithName:@"IOException" reason:@"Unsupported CSR algorithm" userInfo:nil];
  //  }
  //
  //  // Parse the tree
  //  Kdb4Parser *parser = [[Kdb4Parser alloc] initWithRandomStream:randomStream];
  //  Kdb4Tree *tree = [parser parse:stream error:nil];
  //
  //  // Copy some parameters into the KdbTree
  //  tree.rounds = rounds;
  //  tree.compressionAlgorithm = compressionAlgorithm;
  
  return nil;
}

@end