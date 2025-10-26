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
		set targetAccount to missing value

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
					set targetAccount to acc
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
		-- If parentFolder is missing value (top-level), create at account level
		try
			if parentFolder is missing value then
				set newFolder to make new folder at targetAccount with properties {name:newFolderName}
			else
				set newFolder to make new folder at parentFolder with properties {name:newFolderName}
			end if
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

		-- Ensure we're in a clean state before starting
		activate
		delay 0.5

		-- Clear any selection or focus from folder creation
		tell application "System Events"
			tell process "Notes"
				key code 53 -- Escape key to clear any dialogs or selections
				delay 0.3
			end tell
		end tell

		show targetFolder
		delay 1.5

		-- Recursively copy folder contents
		set totalCopied to 0
		set totalCopied to my copyFolderRecursive(targetFolder, newFolder, totalCopied, "")

		log ""
		log "Success! Created folder \"" & newFolderName & "\" with " & totalCopied & " note(s) total"
	end tell
end run

-- Recursively copy notes and subfolders
on copyFolderRecursive(sourceFolder, destFolder, totalCopied, indent)
	tell application "Notes"
		-- Get notes from this folder
		set notesList to notes of sourceFolder
		set noteCount to count of notesList

		if noteCount > 0 then
			log indent & "Copying " & noteCount & " note(s) from " & (name of sourceFolder)

			-- Copy each note using UI automation
			repeat with i from 1 to noteCount
				try
					set theNote to item i of notesList
					set noteName to (name of theNote) as text
					log indent & "  [" & i & "/" & noteCount & "] " & noteName

					-- Ensure Notes is fully activated and visible
					activate
					delay 0.5

					-- Show the specific note directly
					show theNote
					delay 3

					-- Use UI scripting to select and copy the note content
					tell application "System Events"
						tell process "Notes"
							try
								set frontmost to true
								delay 0.8

								-- Only use Tab for the very first note (to move from folder list to content)
								-- For subsequent notes, show theNote already focuses correctly
								set usedTab to false
								if i = 1 and totalCopied = 0 then
									key code 48 -- Tab
									delay 0.8
									set usedTab to true
								end if

								-- Select all content
								keystroke "a" using command down
								delay 0.8

								-- Copy the selected content
								keystroke "c" using command down
								delay 0.8

								-- If we used Tab, undo it to remove the tab character from the original note
								if usedTab then
									keystroke "z" using command down -- Undo
									delay 0.5
								end if
							end try
						end tell
					end tell

					-- Switch to the destination folder
					activate
					delay 0.5
					show destFolder
					delay 1.5

					-- Create a new note and paste
					tell application "System Events"
						tell process "Notes"
							set frontmost to true
							delay 0.5
							keystroke "n" using command down
							delay 1.5
							keystroke "v" using command down
							delay 0.8
						end tell
					end tell

					set totalCopied to totalCopied + 1

				on error errMsg
					log indent & "  Warning: Failed to copy note " & i & ": " & errMsg
				end try
			end repeat
		end if

		-- Now process subfolders recursively
		set subfolders to folders of sourceFolder
		if (count of subfolders) > 0 then
			log indent & "Processing " & (count of subfolders) & " subfolder(s) in " & (name of sourceFolder)

			repeat with subFolder in subfolders
				try
					set subFolderName to (name of subFolder) as text
					log indent & "  Creating subfolder: " & subFolderName

					-- Create matching subfolder in destination (no asterisk!)
					set newSubFolder to make new folder at destFolder with properties {name:subFolderName}
					delay 0.5

					-- Recursively copy this subfolder's contents
					set totalCopied to my copyFolderRecursive(subFolder, newSubFolder, totalCopied, indent & "  ")
				on error errMsg
					log indent & "  Warning: Failed to process subfolder " & subFolderName & ": " & errMsg
				end try
			end repeat
		end if
	end tell

	return totalCopied
end copyFolderRecursive

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
