//
//  ArchRole.h
//  ArchRole
//
//  Created by Brent Royal-Gordon on 7/18/11.
//  Copyright 2011 Architechies.
//  
//  This software is licensed under the MIT License.  License text available at:
//    <http://www.opensource.org/licenses/mit-license.php>
//

#import <Foundation/Foundation.h>

@interface NSObject (ArchRole)

// If you can't use INITIALIZE_DECLARED_ROLES, arrange for this to be called.
+ (void)composeDeclaredRoles;
// Semi-internal.
+ (void)composeRoleForProtocol:(Protocol *)roleProtocol;

// Override and return NO for methods you don't want added.  The 'role' 
// parameter can be compared to the return value of +[YourRole role].
+ (BOOL)shouldComposeInstanceMethod:(SEL)selector fromRole:(id)role;
+ (BOOL)shouldComposeClassMethod:(SEL)selector fromRole:(id)role;

// Test if an object/class adopts a given role.  Pass in the return value of 
// +[YourRole role].  This actually tests if the methods in that role were 
// composed into the class.
+ (BOOL)doesRole:(id)role;
- (BOOL)doesRole:(id)role;

@end

// This protocol marks role protocols.
@protocol ArchRole <NSObject> @end

// ArchRole and its subclasses cannot be instantiated; the subclasses 
// essentially just serve as containers for methods.  Treat them like, say, 
// the Class keyword.
@interface ArchRole : NSObject

// Add this role's methods to targetClass.
+ (void)composeIntoClass:(Class)targetClass;

// Return an opaque role object that can be used with +doesRole:.
+ (id)role;

@end

// Use this in any class that uses roles.  This is what copies the methods in; 
// if you forget it, role methods won't be included in your class.
#define INITIALIZE_DECLARED_ROLES + (void)initialize { static dispatch_once_t once; dispatch_once(&once, ^{ [self composeDeclaredRoles]; }); }

