//
//  BLLogger.h
//  Goodies
//
//  Created by André Abou Chami Campana on 24/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#ifndef Goodies_BLLogger_h
#define Goodies_BLLogger_h

#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#   define kBLShouldLogParse
#   define kBLShouldLogFacebook
#   define kBLShouldLogTwitter
#   define kBLShouldLogMain
#   define kBLShouldLogAdmin
#   define kBLShouldLogFiles
#   define kBLShouldLogMedia
#else
#   define DLog(...)
#endif

//Parse
#ifdef kBLShouldLogParse
#   define ParseLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define ParseLog(...)
#endif

//Facebook
#ifdef kBLShouldLogFacebook
#   define FacebookLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define FacebookLog(...)
#endif

//Twitter
#ifdef kBLShouldLogTwitter
#   define TwitterLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define TwitterLog(...)
#endif

//Main
#ifdef kBLShouldLogMain
#   define MainLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define MainLog(...)
#endif

//Admin
#ifdef kBLShouldLogAdmin
#   define AdminLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define AdminLog(...)
#endif

//Files
#ifdef kBLShouldLogFiles
#   define FileLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define FileLog(...)
#endif

//Media
#ifdef kBLShouldLogMedia
#   define MediaLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define MediaLog(...)
#endif

#endif
