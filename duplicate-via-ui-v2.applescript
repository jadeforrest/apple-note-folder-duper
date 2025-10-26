#!/usr/bin/env osascript

(*
 * Duplicate notes by manually selecting each note in the UI
 * This ensures we're copying the correct note each time
 *)

on run argv
	if (count of argv) is 0 then
		log "Error: Please provide a folder path"
		log "Usage: ./duplicate-via-ui-v2.applescript \"/ParentFolder/FolderName\""
		error number 1
	end if

	set folderPath to item 1 of argv
	set pathParts to my splitPath(folderPath)

	if (count of pathParts) = 0 then
		log "Error: Please provide a valid folder path"
		error number 1
	end if

	set targetName to (item -1 of pathParts) as text
	log "Looking for folder: " & folderPath

	tell application "Notes"
		activate
		delay 1

		set targetFolder to missing value
		set parentFolder to missing value

		-- Search for the folder by navigating through each level
		repeat with acc in accounts
			set currentFolders to folders of acc
			set foundFolder to missing value

			-- Navigate through each level of the path
			repeat with i from 1 to (count of pathParts)
				set levelName to (item i of pathParts) as text
				set foundAtLevel to missing value

				-- Search for this level's folder name
				repeat with aFolder in currentFolders
					try
						if (name of aFolder) = levelName then
							set foundAtLevel to aFolder
							exit repeat
						end if
					end try
				end repeat

				-- If we didn't find this level, break out
				if foundAtLevel is missing value then
					exit repeat
				end if

				-- If this is the target (last level), we're done
				if i = (count of pathParts) then
					set targetFolder to foundAtLevel
				else
					-- Otherwise, set up for next level
					set parentFolder to foundAtLevel
					set currentFolders to folders of foundAtLevel
				end if
			end repeat

			if targetFolder is not missing value then exit repeat
		end repeat

		if targetFolder is missing value then
			log "Error: Folder not found: " & folderPath
			error number 1
		end if

		set folderName to name of targetFolder
		log "Found folder: " & folderName

		-- Create new folder with asterisk suffix
		set newFolderName to folderName & "*"
		log "Creating new folder: " & newFolderName

		-- Try to create the folder - if it exists, this will error
		try
			set newFolder to make new folder at parentFolder with properties {name:newFolderName}
			delay 0.5
		on error errMsg
			if errMsg contains "Duplicate" or errMsg contains "duplicate" or errMsg contains "already exists" then
				log "Error: Folder \"" & newFolderName & "\" already exists. Please rename or delete it first."
				error number 1
			else
				-- Some other error, re-throw it
				error errMsg
			end if
		end try

		-- Get notes
		set notesList to notes of targetFolder
		set noteCount to count of notesList
		log "Found " & noteCount & " note(s) to copy"

		-- Store note names for reference
		set noteNames to {}
		repeat with theNote in notesList
			set end of noteNames to (name of theNote)
		end repeat

		-- Copy each note using UI automation with explicit clicking
		set copiedCount to 0
		repeat with i from 1 to noteCount
			try
				set noteName to item i of noteNames
				log "  Copying note " & i & "/" & noteCount & ": " & noteName

				-- Ensure Notes is activated and visible
				activate
				delay 0.5

				-- Show the source folder
				show targetFolder
				delay 1

				-- Use UI scripting to click on the specific note by name
				tell application "System Events"
					tell process "Notes"
						-- Click on the note list to ensure it's focused
						try
							-- Find and click the note with this name
							-- This is a bit fragile but should work for the note list
							set frontmost to true
							delay 0.5

							-- Use keyboard navigation to select the first note, then navigate
							-- This is more reliable than trying to click
							keystroke "1" using {command down}
							delay 0.5

							-- Navigate down to the correct note (i-1 times)
							repeat (i - 1) times
								key code 125 -- down arrow
								delay 0.2
							end repeat
							delay 0.5

							-- Tab to move focus from note list to content area
							key code 48 -- tab key
							delay 0.5

							-- Now copy the note content (while still in Notes process)
							keystroke "a" using command down
							delay 0.5
							keystroke "c" using command down
							delay 0.5
						end try
					end tell
				end tell

				-- Switch to the destination folder
				activate
				delay 0.5
				show newFolder
				delay 1

				-- Create a new note and paste
				tell application "System Events"
					tell process "Notes"
						set frontmost to true
						delay 0.5
						keystroke "n" using command down
						delay 1
						keystroke "v" using command down
						delay 0.5
					end tell
				end tell

				set copiedCount to copiedCount + 1

			on error errMsg
				log "  Warning: Failed to copy note " & i & ": " & errMsg
			end try
		end repeat

		log ""
		log "Success! Created folder \"" & newFolderName & "\" with " & copiedCount & " note(s)"
	end tell
end run

on splitPath(folderPath)
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to "/"
	set parts to every text item of folderPath
	set AppleScript's text item delimiters to oldDelimiters

	set cleanParts to {}
	repeat with part in parts
		if (length of part) > 0 then
			set end of cleanParts to part
		end if
	end repeat

	return cleanParts
end splitPath
