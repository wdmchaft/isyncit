/*
 * ISI_MenusController.m
 *
 * iSyncIt
 * Simple Sync Software
 * 
 * Created By digital:pardoe
 * 
 */

#import "ISI_MenusController.h"

@implementation ISI_MenusController

- (void)awakeFromNib
{
	// Pull to front, mainly for first runs.
	[NSApp activateIgnoringOtherApps:YES];
	
	// First run, start-up checks.
	startupChecks();
	
	// Load the user preferences file into memory.
	defaults = [NSUserDefaults standardUserDefaults];
	
	[self readMenuDefaults];
	
	[self initialiseMenu];
	
	growler = [[DPGrowl alloc] init];
	
	[growler initializeGrowl:3];

	// Read the bluetooth settings from user defaults.
	enableBluetooth = [defaults boolForKey:@"ISI_EnableBluetooth"];
	
	// Start the scheduler.
	schedulingControl = [[ISI_Scheduling alloc] init];
	[schedulingControl goSchedule];
}

- (void)initialiseMenu
{
	// Fill the menu bar item.
    menuBarItem = [[[NSStatusBar systemStatusBar]
            statusItemWithLength:NSSquareStatusItemLength] retain];
	
	// Set up the menu bar item & fill it.
    [menuBarItem setHighlightMode:YES];
	
	[self changeMenu];
	
	// Initialise the menu bar so the user can operate the program.
    [menuBarItem setMenu:menuMM_Out];
    [menuBarItem setEnabled:YES];
}

- (void)readMenuDefaults
{
	// Read the icon settings from user defaults.
	menuBarIcon = [defaults boolForKey:@"ISI_AlternateMenuBarItem"];
}

- (void)changeMenu
{
	if (menuBarIcon == TRUE) {
		if ((BTPowerState() ? "on" : "off") == "off") {
			[menuBarItem setImage:[NSImage imageNamed:@"ISI_MenuIconAlternate"]];
		} else {
			[menuBarItem setImage:[NSImage imageNamed:@"ISI_MenuIconAlternate_On"]]; 
		}
	} else {
		if ((BTPowerState() ? "on" : "off") == "off") {
			[menuBarItem setImage:[NSImage imageNamed:@"ISI_MenuIcon"]];
		} else {
			 [menuBarItem setImage:[NSImage imageNamed:@"ISI_MenuIcon_On"]];
		}
	}
	
	NSString *tempString = [@"" stringByAppendingString:[[defaults objectForKey:@"ISI_LastSync"] descriptionWithCalendarFormat:@"%a %d %b, %H:%M" timeZone:[NSTimeZone systemTimeZone] locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]]];
	[menuMM_Out_LastSync setTitle:[[[@"" stringByAppendingString:@"Last Sync"] stringByAppendingString:@": "] stringByAppendingString:tempString]];
}

- (IBAction)menuBM_Act_SendFile:(id)sender
{
	// Opens the bluetooth file exchange.
	NSString *sendFilesString = @"tell application \"Bluetooth File Exchange\"\r activate\r end tell";
	NSAppleScript *sendFilesScript = [[NSAppleScript alloc] initWithSource:sendFilesString];
	[sendFilesScript executeAndReturnError:nil];
}

- (IBAction)menuBM_Act_SetUpDev:(id)sender
{
	// Open the bluetooth setup assistant.
	NSString *setDeviceString = @"tell application \"Bluetooth Setup Assistant\"\r activate\r end tell";
	NSAppleScript *setDeviceScript = [[NSAppleScript alloc] initWithSource:setDeviceString];
	[setDeviceScript executeAndReturnError:nil];
}

- (IBAction)menuBM_Act_TurnOn:(id)sender
{
	// Sets the power state to on or off depending on which one is already set.
	if (IOBluetoothPreferencesAvailable()) {
		if ((BTPowerState() ? "on" : "off") == "on") {
			BTSetPowerState(0);
			[growler showGrowlNotification : @"2" : @"Bluetooth Off" : @"Your bluetooth hardware has been turned off."];
		} else {
			BTSetPowerState(1);
			[growler showGrowlNotification : @"1" : @"Bluetooth On" : @"Your bluetooth hardware has been turned on."];
		}
	}
			
	[self changeMenu];
}

- (IBAction)menuMM_Act_ChangeLog:(id)sender
{
	// Makes sure the app is frontmost and displays the Change Log.
	[NSApp activateIgnoringOtherApps:YES];
	ISI_WindowController *changeLogWindow = [[ISI_WindowController alloc] initWithWindowNibName:@"ISI_ChangeLog"];
	[changeLogWindow showWindow:self];
}

- (IBAction)menuMM_Act_Preferences:(id)sender
{
	// Makes sure the app is frontmost and displays the Preferences.
	[NSApp activateIgnoringOtherApps:YES];
	
	if (!prefs)
	{
		// Determine path to the sample preference panes
		NSString *pathToPanes = [NSString stringWithFormat:@"%@/../Preference Panes", [[NSBundle mainBundle] resourcePath]];
		
		prefs = [[SS_PrefsController alloc] initWithPanesSearchPath:pathToPanes];
		
		[prefs setAlwaysShowsToolbar:YES];
		[prefs setDebug:NO];
		
		[prefs setAlwaysOpensCentered:YES];
		
		[prefs setPanesOrder:[NSArray arrayWithObjects:@"Bluetooth", @"Scheduling", @"Menu Icon", @"Login Item", @"Updates", nil]];
	}
    
	// Show the preferences window.
	[prefs showPreferencesWindow];
}

- (IBAction)menuMM_Act_SyncNow:(id)sender
{
	syncControl = [[ISI_Sync alloc] init];
	[syncControl startSync : enableBluetooth growl : growler];
}

- (IBAction)menuMM_Act_AboutDialog:(id)sender
{
	// Makes sure the app is frontmost and displays the About dialog.
	[NSApp activateIgnoringOtherApps:YES];
	[NSApp orderFrontStandardAboutPanel:(id)sender];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{    
	// Deactivates the bluetooth menu if bluetooth is not available.
	if (!IOBluetoothPreferencesAvailable()) {
		if (menuItem == menuMM_Out_Bluetooth) {
			return NO;
		}
	}
	
	// Runs is bluetooth is available.
	if (IOBluetoothPreferencesAvailable()) {
		
		// Activates the necessary menu items that will always remain active with bluetooth.
		if (menuItem == menuMM_Out_Bluetooth) {
			return YES;
		}
		if (menuItem == menuBT_Out_TurnOn) {
			return YES;
		}
		
		// Enables the menu items and sets the bluetooth control menu item title if the bluetooth is turned on.
		if ((BTPowerState() ? "on" : "off") == "on") {
			[menuBT_Out_TurnOn setTitle:[NSString stringWithFormat:@"Turn Off"]];
			if (menuItem == menuBT_Out_SendFile) {
				return YES;
			}
			if (menuItem == menuBT_Out_SetUpDev) {
				return YES;
			}
		}
		
		// Disables the menu items and sets the bluetooth control menu item title if the bluetooth is turned off.
		if ((BTPowerState() ? "on" : "off") == "off") {
			[menuBT_Out_TurnOn setTitle:[NSString stringWithFormat:@"Turn On"]];
			if (menuItem == menuBT_Out_SendFile) {
				return NO;
			}
			if (menuItem == menuBT_Out_SetUpDev) {
				return NO;
			}
		}
	}
}

- (IBAction)menuMM_Act_Donate:(id)sender
{
	// Forces the user into donation.
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=contact%40digitalpardoe%2eco%2euk&item_name=digital%3apardoe&no_shipping=1&no_note=1&tax=0&currency_code=GBP&lc=GB&bn=PP%2dDonationsBF&charset=UTF%2d8"]];
}


- (void)dealloc
{
	// De-allocate the necessary resources.
	[menuBT_Out_SendFile release];
    [menuBT_Out_SetUpDev release];
    [menuBT_Out_TurnOn release];
    [menuMM_Out release];
    [menuMM_Out_Bluetooth release];
    [menuMM_Out_LastSync release];
	[menuMM_Out release];
	[menuBarItem release];
	[schedulingControl release];
	[syncControl release];
	[defaults release];
	[growler release];
	[prefs release];
	[super dealloc];
}

@end
