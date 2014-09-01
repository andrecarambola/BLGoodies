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
#define isRetina ([UIScreen mainScreen].scale == 2.0f)
#define isiPhone5 (!isiPad && isRetina && [UIScreen mainScreen].bounds.size.height > 480.0f)
#define isLandscape (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
#define bundleID [[NSBundle mainBundle] bundleIdentifier]
#define appName [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]
#define kBLDefaultAnimationTime .8f
#define kBLTimeoutTimeForNoConnection 0.0
#define kBLTimeoutTimeFor3G 10.0
#define kBLTimeoutTimeForWiFI 5.0

#endif
