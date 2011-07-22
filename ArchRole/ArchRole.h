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

/* 
 * A role is basically a parallel class and interface.
 * 
 * The interface is applied to any class that adopts the role.  Methods that must 
 * be implemented by those classes are marked @required; methods supplied by the 
 * role are marked @optional.  The interface must also conform to the ArchRole 
 * protocol; it may also conform to other roles' protocols, but ArchRole must 
 * be explicitly listed (otherwise the role machinery will assume it's an 
 * ordinary protocol).
 * 
 * @protocol MyRole <AnotherRole, AThirdRole, ArchRole>
 * - (void)requiredMethod;
 * @optional
 * - (void)providedMethod1;
 * - (void)providedMethod2;
 * @end
 * 
 * The class (which must have the same name as the role) must inherit directly 
 * from ArchRole and must implement all of the optional methods listed in the 
 * protocol.  All methods implemented in the class--even ones not listed in 
 * the protocol--will be added to classes that do the role.
 * 
 * @interface MyRole : ArchRole
 * - (void)providedMethod1;
 * - (void)providedMethod2;
 * @end
 * @interface MyRole (ConvenienceDeclarations) <AnotherRole, AThirdRole, ArchRole>
 * - (void)requiredMethod;
 * @end
 * 
 * The easiest way to achieve this is to use the objc-rolec preprocessor.  This 
 * accepts Objective-C files with an .rh extension and syntax like:
 * 
 * @role MyRole <AnotherRole, AThirdRole>
 * 
 * - (void)requiredMethod;
 * 
 * @provides
 * 
 * - (void)providedMethod1;
 * - (void)providedMethod2;
 * 
 * @end
 * 
 * And creates a counterpart .h file with standard Objective-C syntax.  Note 
 * that objc-rolec does not really understand Objective-C syntax, so be careful 
 * with comments, preprocessor directives, and string literals.
 * 
 * To adopt a role in your class, adopt its protocol and arrange for 
 * +[YourClass composeDeclaredRoles] to be called.  The easiest way to do this
 * is to add INITIALIZE_DECLARED_ROLES at the top of your @implementation 
 * section, which will insert an +initialize method for you.  If you have your
 * own +initialize method, call it there instead.
 */

@interface NSObject (ArchRole)

+ (void)composeDeclaredRoles;
+ (void)composeRoleForProtocol:(Protocol *)roleProtocol;

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

