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

	if (count of pathParts) ≠ 2 then
		log "Error: Currently only supports two-level paths like /Parent/Child"
		error number 1
	end if

	set parentName to (item 1 of pathParts) as text
	set targetName to (item 2 of pathParts) as text

	log "Looking for folder: " & folderPath

	tell application "Notes"
		activate
		delay 1

		set targetFolder to missing value
		set parentFolder to missing value

		-- Search for the folder
		repeat with acc in accounts
			set topFolders to folders of acc

			repeat with aFolder in topFolders
				try
					if (name of aFolder) = parentName then
						set parentFolder to aFolder
						set subfolders to folders of aFolder

						repeat with subFolder in subfolders
							try
								if (name of subFolder) = targetName then
									set targetFolder to subFolder
									exit repeat
								end if
							end try
						end repeat
					end if
				end try

				if targetFolder is not missing value then exit repeat
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

				-- Show the source folder
				show targetFolder
				delay 0.8

				-- Use UI scripting to click on the specific note by name
				tell application "System Events"
					tell process "Notes"
						-- Click on the note list to ensure it's focused
						try
							-- Find and click the note with this name
							-- This is a bit fragile but should work for the note list
							set frontmost to true
							delay 0.3

							-- Use keyboard navigation to select the first note, then navigate
							-- This is more reliable than trying to click
							keystroke "1" using {command down}
							delay 0.3

							-- Navigate down to the correct note (i-1 times)
							repeat (i - 1) times
								key code 125 -- down arrow
								delay 0.2
							end repeat
							delay 0.3
						end try
					end tell
				end tell

				-- Now copy the note content
				tell application "System Events"
					keystroke "a" using command down
					delay 0.3
					keystroke "c" using command down
					delay 0.5
				end tell

				-- Switch to the destination folder
				show newFolder
				delay 0.8

				-- Create a new note and paste
				tell application "System Events"
					keystroke "n" using command down
					delay 1
					keystroke "v" using command down
					delay 0.5
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
