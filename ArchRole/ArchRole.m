//
//  ArchRole.m
//  ArchRole
//
//  Created by Brent Royal-Gordon on 7/18/11.
//  Copyright 2011 Architechies.
//  
//  This software is licensed under the MIT License.  License text available at:
//    <http://www.opensource.org/licenses/mit-license.php>
//

#import "ArchRole.h"

#import <objc/runtime.h>

@interface NSObject (ArchRoleInternal)

+ (void)arch_addDoesRole:(Class)role;
+ (void)arch_setRole:(Class)role forSelector:(SEL)selector;
+ (Class)arch_roleForSelector:(SEL)selector;

@end

@implementation ArchRole

+ (id)role {
    return self;
}

+ (id)allocWithZone:(NSZone *)zone {
    @throw [NSException exceptionWithName:NSGenericException reason:[NSString stringWithFormat:@"Can't instantiate instances of role %@", [self class]] userInfo:nil];
    return nil;
}

+ (void)arch_copyClassMethods:(BOOL)classMethods fromClass:(Class)fromClass toClass:(Class)toClass {
    Class sourceClass = fromClass;
    Class targetClass = toClass;
    
    if(classMethods) {
        fromClass = object_getClass(fromClass);
        toClass   = object_getClass(toClass);
    }
    
    unsigned int methodCount;
	Method * methods = class_copyMethodList(fromClass, &methodCount);
	
	for(unsigned int i = 0; i < methodCount; i++) {
		Method method = methods[i];
		
		SEL selector = method_getName(method);
		IMP implementation = method_getImplementation(method);
		const char * types = method_getTypeEncoding(method);
        
        BOOL shouldCompose = YES;
        
        if(classMethods) {
            shouldCompose = [targetClass shouldComposeClassMethod:selector fromRole:sourceClass];
        }
        else {
            shouldCompose = [targetClass shouldComposeInstanceMethod:selector fromRole:sourceClass];
        }
        
        if(!shouldCompose) {
            // skip this
            continue;
        }
		
		if([toClass arch_roleForSelector:selector]) {
			Class otherClass = [toClass arch_roleForSelector:selector];
			@throw [NSException exceptionWithName:NSInternalInconsistencyException 
										   reason:[NSString stringWithFormat:@"Roles %@ and %@ both try to add method %@ to class %@", 
                                                   NSStringFromClass(fromClass), NSStringFromClass(otherClass),
                                                   NSStringFromSelector(selector), NSStringFromClass(self)] 
										 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												   [NSArray arrayWithObjects:fromClass, otherClass, nil], @"roles",
												   NSStringFromSelector(selector), @"selectorName",
												   toClass, @"class",
												   nil]];
		}
		
		if(class_addMethod(toClass, selector, implementation, types)) {
			[toClass arch_setRole:fromClass forSelector:selector];
		}
	}
    
	free(methods);
}

+ (void)composeIntoClass:(Class)targetClass {
	if([targetClass doesRole:self]) {
		// already did this role
		return;
	}
	
	if(targetClass == self) {
		// Oops, can't compose yourself in
		return;
	}
    
    unsigned int ivarCount = 0;
    Ivar * ivars = class_copyIvarList(self, &ivarCount);
    
    if(ivarCount != 0) {
        NSString * ivarNames = [NSString stringWithUTF8String:ivar_getName(*ivars)];
        
        while(*(++ivars)) {
            [ivarNames stringByAppendingFormat:@", %@", [NSString stringWithUTF8String:ivar_getName(*ivars)]];
        }
        
        NSString * message = [NSString stringWithFormat:@"Role %@ should not have any instance variables, but has %d of them: %@", self, ivarCount, ivarNames];
        
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:message userInfo:nil];
    }
    
    [self arch_copyClassMethods:NO  fromClass:self toClass:targetClass];
    [self arch_copyClassMethods:YES fromClass:self toClass:targetClass];
	
    [targetClass arch_addDoesRole:self];
}


@end

@implementation NSObject (ArchRole)

+ (BOOL)shouldComposeInstanceMethod:(SEL)selector fromRole:(id)role {
    return YES;
}

+ (BOOL)shouldComposeClassMethod:(SEL)selector fromRole:(id)role {
    return selector != @selector(initialize);
}

+ (void)composeDeclaredRoles {
	unsigned int protocolCount;
	Protocol ** protocols = class_copyProtocolList(self, &protocolCount);
	
	for(unsigned int i = 0; i < protocolCount; i++) {
		Protocol * protocol = protocols[i];
		
		if(protocol_isEqual(protocol, @protocol(ArchRole))) {
			continue;
		}
        
		if(!protocol_conformsToProtocol(protocol, @protocol(ArchRole))) {
			continue;
		}
		
		// protocol is a role
		[self composeRoleForProtocol:protocol];
	}
	
	free(protocols);
}

+ (void)composeRoleForProtocol:(Protocol *)role {
	const char * roleName = protocol_getName(role);
	Class methodStorage = objc_lookUpClass(roleName);
	
	if(!methodStorage) {
		// No matching class!
		@throw [NSException exceptionWithName:NSInternalInconsistencyException 
									   reason:[NSString stringWithFormat:@"Role %@ does not have matching method storage class", NSStringFromProtocol(role)] 
									 userInfo:[NSDictionary dictionaryWithObject:role forKey:@"role"]];
	}
	
	[methodStorage composeIntoClass:self];
}

+ (BOOL)doesRole:(id)role {
    const char * roleName = class_getName(role);
    return objc_getAssociatedObject(self, roleName) != nil;
}

- (BOOL)doesRole:(id)role {
    return [[self class] doesRole:role];
}

@end

@implementation NSObject (ArchRoleInternal)

+ (void)arch_addDoesRole:(Class)role {
    const char * roleName = class_getName(role);
    objc_setAssociatedObject(self, roleName, self, OBJC_ASSOCIATION_RETAIN);
}

+ (void)arch_setRole:(Class)role forSelector:(SEL)selector {
    objc_setAssociatedObject(self, selector, role, OBJC_ASSOCIATION_ASSIGN);
}

+ (Class)arch_roleForSelector:(SEL)selector {
    return objc_getAssociatedObject(self, selector);
}

@end
