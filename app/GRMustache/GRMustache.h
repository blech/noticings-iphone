// The MIT License
// 
// Copyright (c) 2010 Gwendal Roué
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import "GRMustacheAvailabilityMacros.h"

enum {
    GRMustacheTemplateOptionNone = 0,
    GRMustacheTemplateOptionMustacheSpecCompatibility = 0x01,
};

typedef NSUInteger GRMustacheTemplateOptions;


/**
 A C struct that hold GRMustache version information
 
 @since v1.0.0
 */
typedef struct {
	int major;	/**< The major component of the version. */
	int minor;	/**< The minor component of the version. */
	int patch;	/**< The patch-level component of the version. */
} GRMustacheVersion;


/**
 The GRMustache class provides with global-level information and configuration
 of the GRMustache library.
 @since v1.0.0
 */
@interface GRMustache: NSObject

//////////////////////////////////////////////////////////////////////////////////////////
/// @name Getting the GRMustache version
//////////////////////////////////////////////////////////////////////////////////////////

/**
 @returns the version of GRMustache as a GRMustacheVersion.
 
 @since v1.0.0
 */
+ (GRMustacheVersion)version AVAILABLE_GRMUSTACHE_VERSION_1_0_AND_LATER;

//////////////////////////////////////////////////////////////////////////////////////////
/// @name Handling of boolean properties
//////////////////////////////////////////////////////////////////////////////////////////

/**
 A Boolean value that determines whether GRMustache renders templates in strict
 boolean mode.
 
 @returns YES if GRMustache renders templates in strict boolean mode,
 NO otherwise. The default value is NO.
 
 In strict boolean mode, properties of context objects that are declared as BOOL
 are interpreted as numbers, and can not be used for controlling Mustache
 boolean sections.
 
 In non-strict boolean mode, all properties declared as signed char (including
 those declared as BOOL), are interpreted as booleans, and can be used for
 controlling Mustache boolean sections.
 
 @see GRMustache#setStrictBooleanMode:
 @see GRYes
 @see GRNo
 @since v1.0.0
 */
+ (BOOL)strictBooleanMode AVAILABLE_GRMUSTACHE_VERSION_1_0_AND_LATER;

/**
 Sets the strict boolean mode of GMustache.
 
 @param aBool YES if GRMustache should render templates in strict boolean mode,
 NO otherwise.
 
 @see GRMustache#strictBooleanMode
 @since v1.0.0
 */
+ (void)setStrictBooleanMode:(BOOL)aBool AVAILABLE_GRMUSTACHE_VERSION_1_0_AND_LATER;

+ (void)preventNSUndefinedKeyExceptionAttack AVAILABLE_GRMUSTACHE_VERSION_1_7_AND_LATER;

+ (GRMustacheTemplateOptions)defaultTemplateOptions AVAILABLE_GRMUSTACHE_VERSION_1_8_AND_LATER;

+ (void)setDefaultTemplateOptions:(GRMustacheTemplateOptions)templateOptions AVAILABLE_GRMUSTACHE_VERSION_1_8_AND_LATER;

@end

#import "GRMustacheSection.h"
#import "GRMustacheTemplate.h"
#import "GRMustacheTemplateLoader.h"
#import "GRMustacheContext.h"
#import "GRMustacheLambda.h"
#import "GRBoolean.h"
#import "GRMustacheEnvironment.h"
#import "GRMustacheError.h"
#import "GRMustacheVersion.h"
