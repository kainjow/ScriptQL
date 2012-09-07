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
	
	NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL:(NSURL *)url error:NULL];
	if (script)
	{
		// try RTF data first
		NSAttributedString *richText = [script richTextSource];
		NSData *richTextData = [richText RTFFromRange:NSMakeRange(0, [richText length]) documentAttributes:nil];
		if (richText && richTextData)
		{
			QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)richTextData, kUTTypeRTF, NULL);
		}
		else
		{
			// try plain text
			NSString *plainText = [script source];
			NSData *plainTextData = [plainText dataUsingEncoding:NSUTF8StringEncoding];
			if (plainText)
				QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)plainTextData, kUTTypePlainText, NULL);
		}
		
		[script release];
	}

	[pool drain];
	
    return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
