#!/bin/bash

####################################################################################################
#
# Copyright (c) 2021 Jamf, All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#   * Neither the name of JAMF nor the names of its contributors may be used
#	  to endorse or promote products derived from this software without specific
#     prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY JAMF "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL JAMF BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
####################################################################################################
# SUPPORT FOR THIS PROGRAM
#
# This program is distributed "as is" by the Jamf Professional Services Team. For more
# information or support for this script, please contact your Jamf Customer Success Manager.
#
####################################################################################################
# ABOUT
#
# Name: ReEnroller Enrollment Prompt.sh
# Author: Andrew Needham, Jamf Professional Services Engineer
# Version: 1.1
#
# This script is designed to be run from the destination Jamf Pro server immediately after running
# ReEnroller. The script will check for the most appropriate type of enrollment (ADE or UIE) and
# will display Jamf Helper dialogs to guide the end-user to installing the MDM profile.
# Tested on macOS Big Sur.
#
# Standard/Admin users - If the logged in user is admin, this script will present ADE or UIE
# depending on whether it detects an ADE record. If the end-user is standard it will only present
# UIE. Standard users will need help from an Admin in order to complete the process. Alternatively
# you may elect to deploy another script which will temporarily make the logged in user an admin.
#
# *NOTE* Uncheck "Call Automated Device Enrollment" in ReEnroller. This script will
# call ADE if appropriate, doing so with ReEnroller as well could get a little confusing for the
# end-user.
#
# Instructions
# * Upload ReEnroller Enrollment Prompt script to destination Jamf Pro server
# * Fill out parameter labels
# 	- Parameter 4 - Title
# 	- Parameter 5 - Message line 1
# 	- Parameter 6 - Message line 2
# 	- Parameter 7 - Custom icon path
# 	- Parameter 8 - Jamf Pro invitation code (optional)
#	- Parameter 9 - Custom trigger to run at end of successful re-enrollment
# * Create a Smart Computer Group
#   - Name: macOS Big Sur or newer with Supervision status = No
#   - Criteria: Supervised
#   - Operator: is
#   - Value: No
#   - Criteria: Operating System Version
#   - Operator: greater than or equal
#   - Value: 11
# * Create a Policy
#   - Name: ReEnroller Enrollment Prompt
#   - Trigger: Recurring Check-in
#   - Execution Frequency: Ongoing (or less frequently if desired)
#   - Payload: Script
#	  Fill out the parameter fields with a title, message, icon and invitation code if desired,
# 	  default values will be used if you do not provide your own.
#   - Scope: macOS Big Sur or newer with Supervision status = No (Smart Computer Group)
#   - Payload: Maintenance
#	  Ensure that Update Inventory is checked
# * Make a note of the policy ID, this should be specified as the "Run policy after verifying
#	migration" Policy ID when building your ReEnroller package.
#
# Invitation code - If a Jamf Pro invitation code is provided, end-users will not be required to
# log in to the Jamf Pro User-Initiated Enrollment page to download the new MDM profile. Leave this
# parameter blank if you wish to prompt for authentication at this step. You can generate invitation
# codes through the enrollment invitations menu.
#
# Upon successful re-enrollment this script will touch a "flag file" to
# /Library/Application Support/JAMF/Receipts/com.jamfps.migrateSuccess.pkg
# If you wish to monitor for computers which have completed this process, you can create a Smart
# Computer Group to identify computers these computers with the "Packages Installed By Casper"
# criteria.
#
# Timeouts - Jamf Helper windows will timeout after the following periods of time. When the window
# times out, it assumes the default button has been pressed.
# "Enroll" window - 10 minutes
# "Instructions" windows - 5 minutes
# "Thanks" window - 1 minute
#
####################################################################################################

## VARIABLES ##

title="$4"
description="$5"
description2="$6"
icon="$7"
inviteCode="$8"
customTrigger="$9"

if [[ $title == "" ]]; then
	/bin/echo "No title specified, using default title"
	title="Important Message from IT"
fi

if [[ $description == "" ]]; then
	/bin/echo "No description line 1 specified, using default description line 1"
	description="Your computer is not fully enrolled in your organization's management server."
fi

if [[ $description2 == "" ]]; then
	/bin/echo "No description line 2 specified, using default description line 2"
	description2="Please click Enroll and follow the instructions to help keep your computer safe and secure. This will only take a few minutes."
fi

if [[ $icon == "" ]]; then
	/bin/echo "No icon specified, using default icon"
	icon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarAdvanced.icns"
fi

jssURL=$( /usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url )
/bin/echo "JSS URL is $jssURL"
if [[ $inviteCode == "" ]]; then
	uieURL="${jssURL}enroll"
else
	uieURL="${jssURL}enroll/?invitation=$inviteCode"
fi
echo "Enrollment URL is $uieURL"

jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

## FUNCTIONS ##

workflowADE() {
/bin/echo "Displaying Jamf Helper window"
"$jamfHelper" \
-windowType "utility" \
-title "$title" \
-icon "$icon" \
-description "$description

$description2" \
-alignDescription "center" \
-button1 "Enroll" \
-timeout "600" \
-defaultButton "1" > /dev/null 2>&1

/bin/echo "User has clicked Enroll, calling Automated Device Enrollment"
/usr/bin/profiles renew -type enrollment

/bin/echo "Displaying instructions window"
"$jamfHelper" \
-windowType "utility" \
-windowPosition "ul" \
-title "How to install the MDM Profile" \
-description "1) Click the DEVICE ENROLLMENT notification in the top right corner of your screen
2) Click ALLOW and enter your password when prompted

NOTE: If you don't see a notification, make sure Do Not Disturb mode is switched off

After you've installed the MDM profile please click Done" \
-button1 "Done" \
-timeout "300" \
-defaultButton "1" > /dev/null 2>&1

/bin/echo "The user has clicked Done, checking for MDM profile installation"

enrollStatus=$( /usr/bin/profiles status -type enrollment | grep "MDM enrollment:" )
if [[ $enrollStatus == *"MDM enrollment: Yes"* ]]; then
	/bin/echo "MDM profile is installed"
	"$jamfHelper" \
	-windowType "utility" \
	-title "Thank you" \
	-icon "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarFavoritesIcon.icns" \
	-description "Thank you for installing the MDM profile!" \
	-alignDescription "center" \
	-timeout "60" \
	-button1 "Done" \
	-defaultButton "1" > /dev/null 2>&1
	/usr/bin/touch "/Library/Application Support/JAMF/Receipts/com.jamfps.migrateSuccess.pkg"
	if [[ "$customTrigger" != "" ]]; then
		/bin/sleep 30
		/usr/local/bin/jamf policy -event "$customTrigger"
	fi
else
	/bin/echo "MDM profile is not installed"
fi

exit 0
}

workflowUIE() {
/bin/echo "Displaying Jamf Helper window"
"$jamfHelper" \
-windowType "utility" \
-title "$title" \
-icon "$icon" \
-description "$description

$description2" \
-alignDescription "center" \
-button1 "Enroll" \
-timeout "600" \
-defaultButton "1" > /dev/null 2>&1

/bin/echo "User has clicked Enroll, opening User-Initiated Enrollment page in browser"
/usr/bin/su "$loggedInUser" -c "/usr/bin/open '$uieURL'"

"$jamfHelper" \
-windowType "utility" \
-windowPosition "ul" \
-title "How to download the MDM Profile" \
-description "1) Locate the enrollment page in your browser
2) Sign in if prompted
3) Follow the instructions to download the MDM profile

After you've downloaded the MDM profile please click Next" \
-button1 "Next" \
-timeout "300" \
-defaultButton "1" > /dev/null 2>&1
/bin/echo "The user has clicked Next"

/bin/sleep 1
/bin/echo "Opening profiles pane"
/usr/bin/su "$loggedInUser" -c "/usr/bin/open x-apple.systempreferences:com.apple.preferences.configurationprofiles"

"$jamfHelper" \
-windowType "utility" \
-windowPosition "ul" \
-title "How to install the MDM Profile" \
-description "1) Locate the Profiles pane in System Preferences
4) Select MDM Profile and click INSTALL
5) Follow the prompts to complete the installation

After you've installed the MDM profile please click Done" \
-button1 "Done" \
-timeout "300" \
-defaultButton "1" > /dev/null 2>&1

/bin/echo "The user has clicked Done, checking for MDM profile installation"

enrollStatus=$( /usr/bin/profiles status -type enrollment | grep "MDM enrollment:" )
if [[ $enrollStatus == *"MDM enrollment: Yes"* ]]; then
	/bin/echo "MDM profile is installed"
	"$jamfHelper" \
	-windowType "utility" \
	-title "Thank you" \
	-icon "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarFavoritesIcon.icns" \
	-description "Thank you for installing the MDM profile!" \
	-alignDescription "center" \
	-timeout "60" \
	-button1 "Done" \
	-defaultButton "1" > /dev/null 2>&1
	/usr/bin/touch "/Library/Application Support/JAMF/Receipts/com.jamfps.migrateSuccess.pkg"
	if [[ "$customTrigger" != "" ]]; then
		/bin/sleep 30
		/usr/local/bin/jamf policy -event "$customTrigger"
	fi
else
	/bin/echo "MDM profile is not installed"
fi

exit 0
}

## APPLICATION ##

enrollStatus=$( /usr/bin/profiles status -type enrollment | grep "MDM enrollment:" )
if [[ $enrollStatus == *"MDM enrollment: Yes"* ]]; then
	/bin/echo "Computer is enrolled in MDM, submitting inventory and exiting"
	exit 0
fi

loggedInUser=$( /usr/bin/stat -f %Su /dev/console )

if [[ "$loggedInUser" == "root" ]]; then
	/bin/echo "No user logged in, exiting"
	exit 0
fi

## Checks for admin / standard user status (1=admin 0=standard)
adminStatus=$( /usr/bin/dscacheutil -q group -a name admin | grep users: | grep -c "$loggedInUser" )

## Checks whether computer is enrolled
enrollStatus=$( /usr/bin/profiles status -type enrollment | grep "MDM enrollment:" )

if [[ "$adminStatus" == "0" ]]; then
	/bin/echo "Standard user detected"
	workflowUIE
fi

## Checks whether computer has ADE record
adeRecord=$( /usr/bin/profiles show -type enrollment )

/bin/sleep 5

if [[ "$adminStatus" == "1" ]]; then
	/bin/echo "Admin user detected"
	if [[ $adeRecord == *"ConfigurationURL"* ]]; then
		/bin/echo "ADE record found"
		workflowADE
	else
		/bin/echo "ADE record not found"
		workflowUIE
	fi
fi