
// Copyright (c) 2022-2023 Manuel Schneider

#include <Cocoa/Cocoa.h>
#include <CoreServices/CoreServices.h>
#include "plugin.h"
ALBERT_LOGGING
using namespace std;
using namespace albert;


Plugin::Plugin() { registry().add(&dict_handler); }

Plugin::~Plugin() { registry().remove(&dict_handler); }

///////////////////////////////////////////////////////////////////////////////////////////////////

// google DCSGetActiveDictionaries

extern "C" {
  NSArray *DCSGetActiveDictionaries();
  NSArray *DCSCopyAvailableDictionaries();
  NSString *DCSDictionaryGetName(DCSDictionaryRef dictID);
  NSString *DCSDictionaryGetShortName(DCSDictionaryRef dictID);
}

QString DictHandler::id() const { return QStringLiteral("dict"); }

QString DictHandler::name() const { return QStringLiteral("Dictionary"); }

QString DictHandler::description() const { return QStringLiteral("Search in dictionary"); }

QString DictHandler::synopsis() const { return QStringLiteral("<word>"); }

QString DictHandler::defaultTrigger() const { return QStringLiteral("def "); }

void DictHandler::handleTriggerQuery(TriggerQuery &query) const
{
    @autoreleasepool {
        DCSDictionaryRef dic = NULL;
        NSArray *dicts = DCSGetActiveDictionaries();
        for (NSObject *aDict in dicts) {
            dic = static_cast<DCSDictionaryRef>(aDict);

            NSString *word = query.string().toNSString();
            NSString *long_name = DCSDictionaryGetName((DCSDictionaryRef)aDict);
//            NSString *short_name = DCSDictionaryGetShortName((DCSDictionaryRef)aDict);
            NSString *result = (NSString*)DCSCopyTextDefinition(
                dic,
                (CFStringRef)word,
                DCSGetTermRangeInString(nil, (CFStringRef)word, 0)
            );
            if (result){
                auto text = QString::fromNSString(result);
                query.add(StandardItem::make(
                    id(),
                    QString::fromNSString(long_name),
                    text,
                    {":dict"},
                    Actions{{"open","Open in Apple dictionary",[s=query.string()](){ openUrl("dict://"+s); }}}
                 ));
            }
        }
    }
}


