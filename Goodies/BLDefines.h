//
//  BLDefines.h
//  Goodies
//
//  Created by André Abou Chami Campana on 24/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#ifndef Goodies_BLDefines_h
#define Goodies_BLDefines_h

#define isiPad ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define isiOS6 ([[[UIDevice currentDevice] systemVersion] doubleValue] < 7.0)
#define isiOS7 ([[[UIDevice currentDevice] systemVersion] doubleValue] < 8.0)
#define isRetina ([UIScreen mainScreen].scale > 1.0f)
#define isiPhone5 (!isiPad && isRetina && [UIScreen mainScreen].bounds.size.height == 568.0f)
#define isiPhone6 (!isiPad && isRetina && [UIScreen mainScreen].fixedCoordinateSpace.bounds.size.height == 667.0f)
#define isiPhone6Plus (!isiPad && isRetina && [UIScreen mainScreen].fixedCoordinateSpace.bounds.size.height == 736.0f)
#define isScaledUp (isiPhone6Plus && [UIScreen mainScreen].nativeScale > [UIScreen mainScreen].scale)
#define isLandscape (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
#define bundleID [[NSBundle mainBundle] bundleIdentifier]
#define appName [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]
#define kBLDefaultAnimationTime .8f
#define kBLTimeoutTimeForNoConnection 0.0
#define kBLTimeoutTimeFor3G 10.0
#define kBLTimeoutTimeForWiFI 5.0

#endif
