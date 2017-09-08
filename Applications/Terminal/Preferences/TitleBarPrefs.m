/*
  Copyright (C) 2015 Sergii Stoian <stoyan255@ukr.net>

  This file is a part of Terminal.app. Terminal.app is free software; you
  can redistribute it and/or modify it under the terms of the GNU General
  Public License as published by the Free Software Foundation; version 2
  of the License. See COPYING or main.m for more information.
*/

#include "TitleBarPrefs.h"
#import "../TerminalWindow.h"

@implementation TitleBarPrefs

+ (NSString *)name
{
  return @"Title Bar";
}

- init
{
  self = [super init];

  [NSBundle loadNibNamed:@"TitleBar" owner:self];

  return self;
}

- (void)awakeFromNib
{
  [view retain];
}

- (NSView *)view
{
  return view;
}

// Utility
- (NSUInteger)_elementsMaskFromButtons
{
  NSUInteger mask = 0;
  
  if ([shellPathBth state] == NSOnState)
    mask |= TitleBarShellPath;
  if ([deviceNameBtn state] == NSOnState)
    mask |= TitleBarDeviceName;
  if ([filenameBtn state] == NSOnState)
    mask |= TitleBarFileName;
  if ([windowSizeBtn state] == NSOnState)
    mask |= TitleBarWindowSize;
  if ([customTitleBtn state] == NSOnState)
    mask |= TitleBarCustomTitle;

  return mask;
}

// Title bar display format:
// CutomTitle -- ShellPath (DeviceName) WindowSize -- FileName
- (void)_updateDemoTitleBar
{
  NSUInteger elementsMask = [self _elementsMaskFromButtons];
  NSString   *title;
  TerminalWindowController *twc = [[NSApp mainWindow] windowController];

  title = [NSString new];
  
  if (elementsMask & TitleBarShellPath)
    title = [title stringByAppendingFormat:@"%@ ", [twc shellPath]];
  
  if (elementsMask & TitleBarDeviceName)
    title = [title stringByAppendingFormat:@"(%@) ", [twc deviceName]];
  
  if (elementsMask & TitleBarWindowSize)
    title = [title stringByAppendingFormat:@"%@ ", [twc windowSizeString]];
  
  if (elementsMask & TitleBarCustomTitle)
    {
      if ([title length] == 0)
        {
          title = [NSString stringWithFormat:@"%@ ",
                            [customTitleField stringValue]];
        }
      else
        {
          title = [NSString stringWithFormat:@"%@ \u2014 %@",
                            [customTitleField stringValue], title];
        }
    }

  if (elementsMask & TitleBarFileName)
    {
      if ([title length] == 0)
        {
          title = [NSString stringWithFormat:@"%@", [twc fileName]];
        }
      else
        {
          title = [title stringByAppendingFormat:@"\u2014 %@", [twc fileName]];
        }
    }
  
  [demoTitleBarField setStringValue:title];
}

- (void)_updateControls:(Defaults *)defs
{
  NSUInteger titleBarMask = [defs titleBarElementsMask];
  NSString   *customTitle = [defs customTitle];

  [shellPathBth setState:(titleBarMask & TitleBarShellPath) ? 1 : 0];
  [deviceNameBtn setState:(titleBarMask & TitleBarDeviceName) ? 1 : 0];
  [filenameBtn setState:(titleBarMask & TitleBarFileName) ? 1 : 0];
  [windowSizeBtn setState:(titleBarMask & TitleBarWindowSize) ? 1 : 0];
  [customTitleBtn setState:(titleBarMask & TitleBarCustomTitle) ? 1 : 0];

  if (!customTitle)
    [customTitleField setStringValue:@"Terminal"];
  else
    [customTitleField setStringValue:customTitle];
  
  [self setElements:self];
}

- (void)setElements:(id)sender
{
  if ([customTitleBtn state] == NSOnState)
    {
      [customTitleField setEditable:YES];
      [customTitleField setTextColor:[NSColor blackColor]];
      [[view window] makeFirstResponder:customTitleField];
    }
  else
    {
      [customTitleField setEditable:NO];
      [customTitleField setTextColor:[NSColor darkGrayColor]];
      [[view window] makeFirstResponder:window];
    }

  [self _updateDemoTitleBar];
}

- (void)setDefault:(id)sender
{
  Defaults   *defs = [[Preferences shared] mainWindowPreferences];
  NSUInteger titleBarMask = [self _elementsMaskFromButtons];
  
  [defs setTitleBarElementsMask:titleBarMask];
  if (titleBarMask & TitleBarCustomTitle)
    {
      [defs setCustomTitle:[customTitleField stringValue]];
    }

  [defs synchronize];
}
- (void)showDefault:(id)sender
{
  [self _updateControls:[[Preferences shared] mainWindowPreferences]];
}

- (void)showWindow
{
  [self _updateControls:[[Preferences shared] mainWindowLivePreferences]];
}
- (void)setWindow:(id)sender
{
  Defaults     *prefs;
  NSDictionary *uInfo;
  NSUInteger   titleBarMask;

  if (![sender isKindOfClass:[NSButton class]]) return;
  
  prefs = [[Defaults alloc] initEmpty];

  titleBarMask = [self _elementsMaskFromButtons];
  [prefs setTitleBarElementsMask:titleBarMask];
  if (titleBarMask & TitleBarCustomTitle)
    {
      [prefs setCustomTitle:[customTitleField stringValue]];
    }
  
  uInfo = [NSDictionary dictionaryWithObject:prefs forKey:@"Preferences"];
  [prefs release];

  [[NSNotificationCenter defaultCenter]
    postNotificationName:TerminalPreferencesDidChangeNotification
                  object:[NSApp mainWindow]
                userInfo:uInfo];
}


// TextField delegate
- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
  [self _updateDemoTitleBar];
}

@end
