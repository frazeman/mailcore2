//
//  MCOSMTPSendOperation.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/29/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOSMTPSendOperation.h"

#include "MCAsyncSMTP.h"

#import "MCOUtils.h"
#import "MCOOperation+Private.h"
#import "MCOSMTPOperation+Private.h"

#include <stdio.h>

#define nativeType mailcore::SMTPOperation

typedef void (^CompletionType)(NSError *error);

@interface MCOSMTPSendOperation ()

- (void) bodyProgress:(unsigned int)current maximum:(unsigned int)maximum;

@end

class MCOSMTPSendOperationCallback : public mailcore::SMTPOperationCallback {
public:
    MCOSMTPSendOperationCallback(MCOSMTPSendOperation * op)
    {
        mOperation = op;
        printf("ZZRT Created MCOSMTPSendOperationCallback %p for operation %p\n", this, op);
    }
    
    virtual ~MCOSMTPSendOperationCallback()
    {
        printf("ZZRT Dealloced MCOSMTPSendOperationCallback %p for operation %p\n", this, mOperation);
    }
    
    virtual void bodyProgress(mailcore::SMTPOperation * session, unsigned int current, unsigned int maximum) {
        printf("ZZRT MCOSMTPSendOperationCallback %p bodyProgress will call operation bodyProgress\n", this);
        [mOperation bodyProgress:current maximum:maximum];
        printf("ZZRT MCOSMTPSendOperationCallback %p bodyProgress did call operation bodyProgress\n", this);
    }
    
private:
    MCOSMTPSendOperation * mOperation;
};

@implementation MCOSMTPSendOperation {
    CompletionType _completionBlock;
    MCOSMTPSendOperationCallback * _smtpCallback;
    MCOSMTPOperationProgressBlock _progress;
}

@synthesize progress = _progress;

+ (void) load
{
    MCORegisterClass(self, &typeid(nativeType));
}

+ (NSObject *) mco_objectWithMCObject:(mailcore::Object *)object
{
    nativeType * op = (nativeType *) object;
    return [[[self alloc] initWithMCOperation:op] autorelease];
}

- (instancetype) initWithMCOperation:(mailcore::Operation *)op
{
    self = [super initWithMCOperation:op];
    printf("ZZRT MCOSMTPSendOperation %p initWithMCOperation %p\n", self, op);

    _smtpCallback = new MCOSMTPSendOperationCallback(self);
    ((mailcore::SMTPOperation *) op)->setSmtpCallback(_smtpCallback);
    
    return self;
}

- (void) dealloc
{
    mailcore::Object *mco_mcObject = self.mco_mcObject;
    printf("ZZRT MCOSMTPSendOperation %p dealloc. operation pointer is %p\n", self, mco_mcObject);
    if (mco_mcObject) {
// This will prevent a crash (MAIL-451) if the session is dealloced in the complete method. A better solution is to hold on to the session
// and dispose of it later.
        ((mailcore::SMTPOperation *) mco_mcObject)->setSmtpCallback(NULL);
    }

    [_progress release];
    [_completionBlock release];
    delete _smtpCallback;
    [super dealloc];
}

- (void) start:(void (^)(NSError *error))completionBlock
{
    _completionBlock = [completionBlock copy];
    [self start];
}

- (void) cancel
{
    [_completionBlock release];
    _completionBlock = nil;
    [super cancel];
}

// This method needs to be duplicated from MCOSMTPOperation since _completionBlock
// references the instance of this subclass and not the one from MCOSMTPOperation.
- (void)operationCompleted
{
    if (_completionBlock == NULL)
        return;
    
    NSError * error = [self _errorFromNativeOperation];
    _completionBlock(error);
    [_completionBlock release];
    _completionBlock = NULL;
}

- (void) bodyProgress:(unsigned int)current maximum:(unsigned int)maximum
{
    printf("ZZRT MCOSMTPSendOperation %p bodyProgress will call progress block %p\n", self, _progress);
    if (_progress != NULL) {
        _progress(current, maximum);
    }
    printf("ZZRT MCOSMTPSendOperation %p bodyProgress did call progress block %p\n", self, _progress);
}

@end
