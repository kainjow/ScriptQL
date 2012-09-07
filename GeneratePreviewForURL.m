#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <AppKit/AppKit.h>

// In 10.8, and maybe 10.7, if an AppleScript document is edited but not saved manually (so saved via Versions),
// inside its resource fork will contain a 'RTF ' type with the raw rich text of the script. By loading this value
// if it's available we avoid having to compile the script which could launch an application (due to the way AS works).
// Note, this is something I discovered on accident, so it may be gone in future OS X versions.
// Also, this code is from the Carbon/Toolbox Resource Manager and is deprecated as of 10.8.
// You can peek at the resource fork to see if the RTF is there by using 'xattr -l <path>'
static NSData* RTFDataFromResourceFork(CFURLRef url)
{
    NSData *rtfData = nil;
    FSRef ref;
    if (CFURLGetFSRef((CFURLRef)url, &ref) == true) {
        ResFileRefNum refNum = FSOpenResFile(&ref, fsRdPerm);
        if (refNum) {
            const ResType rtfType = 'RTF ';
            if (Count1Resources(rtfType) == 1) {
                Handle handle = Get1IndResource(rtfType, 1);
                if (handle != NULL) {
                    Size handleSize = GetHandleSize(handle);
                    if (handleSize > 0) {
                        rtfData = [NSData dataWithBytes:*handle length:handleSize];
                    }
                    DisposeHandle(handle);
                }
            }
            CloseResFile(refNum);
        }
    }
    return rtfData;
}

/* -----------------------------------------------------------------------------
 Generate a preview for file
 
 This function's job is to create preview for designated file
 ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    @autoreleasepool { @try {
    // Try the RTF data in the resource fork
    NSData *rsrcRTFData = RTFDataFromResourceFork(url);
    if (rsrcRTFData != nil) {
        QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)rsrcRTFData, kUTTypeRTF, NULL);
    } else {
        NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL:(NSURL *)url error:NULL];
        if (script != nil) {
            // try RTF data
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
    }
    } @catch (NSException *ex) {} }
	
    return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
