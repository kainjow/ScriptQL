#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <AppKit/AppKit.h>

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    @try {
	NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL:(NSURL *)url error:NULL];
	if (script != nil) {
		// try RTF data first
		NSAttributedString *richText = [script richTextSource];
		NSData *richTextData = [richText RTFFromRange:NSMakeRange(0, [richText length]) documentAttributes:nil];
		if (richTextData != nil) {
			QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)richTextData, kUTTypeRTF, NULL);
		} else {
			// try plain text
			NSData *plainTextData = [[script source] dataUsingEncoding:NSUTF8StringEncoding];
			if (plainTextData != nil) {
				QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)plainTextData, kUTTypePlainText, NULL);
            }
		}
		[script release];
	}
    } @catch (NSException *ex) {}

	[pool drain];
	
    return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
