# ReEnroller enrollment prompt

Copyright (c) 2021 Jamf, All rights reserved. 

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
   * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 
   * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. 
	* Neither the name of JAMF nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. 
THIS SOFTWARE IS PROVIDED BY JAMF "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL JAMF BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
 
## SUPPORT FOR THIS PROGRAM
 
 This program is distributed "as is" by the Jamf Professional Services Team. For more 
 information or support for this script, please contact your Jamf Customer Success Manager. 
 
 
 ABOUT 
 
 Name: ReEnroller Enrollment Prompt.sh<br />
 Author: Andrew Needham, Jamf Professional Services Engineer<br />
 Version: 1.1<br />
 
 This script is designed to be run from the destination Jamf Pro server immediately after running 
 ReEnroller. The script will check for the most appropriate type of enrollment (ADE or UIE) and 
 will display Jamf Helper dialogs to guide the end-user to installing the MDM profile. 
 Tested on macOS Big Sur. 
 
 Standard/Admin users - If the logged in user is admin, this script will present ADE or UIE 
 depending on whether it detects an ADE record. If the end-user is standard it will only present 
 UIE. Standard users will need help from an Admin in order to complete the process. Alternatively 
 you may elect to deploy another script which will temporarily make the logged in user an admin. 
 
 *NOTE* 
 Uncheck "Call Automated Device Enrollment" in ReEnroller. This script will 
 call ADE if appropriate, doing so with ReEnroller as well could get a little confusing for the 
 end-user. 
 
 Instructions 
 * Upload ReEnroller Enrollment Prompt script to destination Jamf Pro server 
 * Fill out parameter labels 
 	- Parameter 4 - Title 
 	- Parameter 5 - Message line 1 
 	- Parameter 6 - Message line 2 
 	- Parameter 7 - Custom icon path 
 	- Parameter 8 - Jamf Pro invitation code (optional) 
	- Parameter 9 - Custom trigger to run at end of successful re-enrollment 
 * Create a Smart Computer Group 
   - Name: macOS Big Sur or newer with Supervision status = No 
   - Criteria: Supervised 
   - Operator: is 
   - Value: No 
   - Criteria: Operating System Version 
   - Operator: greater than or equal 
   - Value: 11 
 * Create a Policy 
   - Name: ReEnroller Enrollment Prompt 
   - Trigger: Recurring Check-in 
   - Execution Frequency: Ongoing (or less frequently if desired) 
   - Payload: Script 
	  Fill out the parameter fields with a title, message, icon and invitation code if desired, 
 	  default values will be used if you do not provide your own. 
   - Scope: macOS Big Sur or newer with Supervision status = No (Smart Computer Group) 
   - Payload: Maintenance 
	  Ensure that Update Inventory is checked 
 * Make a note of the policy ID, this should be specified as the "Run policy after verifying 
	migration" Policy ID when building your ReEnroller package. 
 
 Invitation code - If a Jamf Pro invitation code is provided, end-users will not be required to 
 log in to the Jamf Pro User-Initiated Enrollment page to download the new MDM profile. Leave this 
 parameter blank if you wish to prompt for authentication at this step. You can generate invitation 
 codes through the enrollment invitations menu. 
 
 Upon successful re-enrollment this script will touch a "flag file" to 
 /Library/Application Support/JAMF/Receipts/com.jamfps.migrateSuccess.pkg 
 If you wish to monitor for computers which have completed this process, you can create a Smart 
 Computer Group to identify computers these computers with the "Packages Installed By Casper" 
 criteria. 
 
 Timeouts - Jamf Helper windows will timeout after the following periods of time. When the window 
 times out, it assumes the default button has been pressed. 
 "Enroll" window - 10 minutes 
 "Instructions" windows - 5 minutes 
 "Thanks" window - 1 minute 

