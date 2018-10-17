//
//  MCOIMAPBaseOperation.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/26/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOIMAPBaseOperation.h"
#import "MCOIMAPBaseOperation+Private.h"

#import "MCOOperation+Private.h"

#import "MCAsyncIMAP.h"
#import "MCOIMAPSession.h"
#import "NSObject+MCO.h"

class MCOIMAPBaseOperationIMAPCallback : public mailcore::IMAPOperationCallback {
public:
    MCOIMAPBaseOperationIMAPCallback(MCOIMAPBaseOperation * op)
    {
        mOperation = op;
    }
    
    virtual ~MCOIMAPBaseOperationIMAPCallback()
    {
    }
    
    virtual void bodyProgress(mailcore::IMAPOperation * session, unsigned int current, unsigned int maximum) {
        [mOperation bodyProgress:current maximum:maximum];
    }
    
    virtual void itemProgress(mailcore::IMAPOperation * session, unsigned int current, unsigned int maximum) {
        [mOperation itemProgress:current maximum:maximum];
    }
    
private:
    MCOIMAPBaseOperation * mOperation;
};

@implementation MCOIMAPBaseOperation {
    MCOIMAPBaseOperationIMAPCallback * _imapCallback;
    MCOIMAPSession * _session;
}

#define nativeType mailcore::IMAPOperation

MCO_OBJC_SYNTHESIZE_SCALAR(BOOL, bool, setUrgent, isUrgent)

- (instancetype) initWithMCOperation:(mailcore::Operation *)op
{
    self = [super initWithMCOperation:op];
    
    _imapCallback = new MCOIMAPBaseOperationIMAPCallback(self);
    ((mailcore::IMAPOperation *) op)->setImapCallback(_imapCallback);
    
    return self;
}

- (void) dealloc
{
    mailcore::Object *mco_mcObject = self.mco_mcObject;
    if (mco_mcObject) {
        // This will prevent a crash if self is dealloced immediately when the operation is completed (which
        // happens when the caller does not retain the operation). In that case the mco_mcObject will still
        // retain a pointer to _smtpCallback even though it is about to be deleted here, while mco_mcObject
        // may continue to exist since it is released by self but not necessarily deleted. If another progress
        // update is received it will message the deleted object and crash.
        ((mailcore::IMAPOperation *) mco_mcObject)->setImapCallback(NULL);
    }

    [_session release];
    delete _imapCallback;
    [super dealloc];
}

- (void) setSession:(MCOIMAPSession *)session
{
    [_session release];
    _session = [session retain];
}

- (MCOIMAPSession *) session
{
    return _session;
}

- (void) bodyProgress:(unsigned int)current maximum:(unsigned int)maximum
{
}

- (void) itemProgress:(unsigned int)current maximum:(unsigned int)maximum
{
}

@end
