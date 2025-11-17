# Apple Notes Folder Duplicator

A utility tool for safely duplicating Apple Notes folders with all their contents, including nested subfolders. **Run on macOS to fix persistent disk space issues on iPad and iOS devices.**

## The Problem

Apple Notes has a bug where notes can leak disk space on iOS and iPad devices (macOS appears unaffected). You'll gradually take up all available storage on your iOS and iPad devices, even though iCloud reports a much smaller usage than Settings → General → Storage shows for Notes.

The only known solution is to recreate all of your notes, which this script helps automate.

## Description

This script creates a deep copy of an Apple Notes folder, recursively duplicating all notes and subfolders within it. The new folder is created with an asterisk suffix (e.g., "Test" becomes "Test*"). Uses UI automation to ensure perfect formatting preservation.

After successfully duplicating your notes, you can delete the original folders to reclaim the leaked disk space on your iOS/iPad devices.

## Features

- Safe folder duplication using AppleScript and UI automation
- Perfectly preserves all note content and formatting
- Recursively copies nested subfolders
- Creates the duplicate in the same parent folder
- Comprehensive error handling and validation
- Prevents accidental overwrites

## Requirements

- macOS with Apple Notes installed
- AppleScript - included with macOS
- Accessibility permissions for Terminal or your script runner

## Installation

1. Clone this repository or download the script
2. Make the script executable:

```bash
chmod +x duplicate-apple-notes-folder.applescript
```

## Usage

Basic usage:

```bash
./duplicate-apple-notes-folder.applescript "/ParentFolder/FolderName"
```

### Examples

Duplicate a folder called "Test" inside "Personal":

```bash
./duplicate-apple-notes-folder.applescript "/Personal/Test"
```

This will create a new folder called "Test*" inside "Personal" with copies of all notes and subfolders from "Test".

Duplicate a top-level folder:

```bash
./duplicate-apple-notes-folder.applescript "/MyFolder"
```

### Path Format

- Use forward slashes to separate folder levels
- Start with a forward slash
- Example: "/ParentFolder/ChildFolder/TargetFolder"

## How It Works

1. The script parses the folder path you provide
2. It navigates through Apple Notes to find the target folder
3. It creates a new folder with the same name plus an asterisk (*)
4. It recursively copies all notes and subfolders from the source to the new folder
5. It uses UI automation to select, copy, and paste notes to preserve perfect formatting
6. It preserves note names, content, and folder structure

## Safety Features

- Validates folder path before proceeding
- Checks if a folder with the duplicate name already exists
- Provides clear error messages if something goes wrong
- Does not modify or delete the original folder
- Does not access the Notes database directly (uses official Apple APIs)

## Limitations

- **Does not preserve note creation dates** - duplicated notes will have new creation timestamps
- Does not copy folder-specific metadata (like color or icon)
- Requires the source folder to exist in Apple Notes
- Uses UI automation which requires the Notes app to be visible during operation

## Troubleshooting

### "Folder not found" error

- Verify the folder path is correct
- Check that the folder exists in Apple Notes
- Ensure you're using the exact folder names (case-sensitive)

### "Folder already exists" error

- A folder with the name "OriginalName*" already exists
- Rename or delete the existing duplicate folder first

### Permission errors

- The first time you run the script, macOS may ask for permission to access Notes
- You may also need to grant Accessibility permissions for UI automation
- Grant the permissions in System Settings > Privacy & Security > Accessibility

## Technical Details

- Written in AppleScript with UI automation
- Uses Apple's official Notes.app scripting interface
- Uses System Events for keyboard automation to preserve formatting
- Safe and non-destructive operation
- No direct database manipulation

## Future Enhancements

Possible improvements for future versions:

- Custom naming for duplicated folders
- Progress bar for large folders
- Selective note copying (filter by criteria)
- Batch folder duplication
- Faster operation without UI automation

## Contributing

Feel free to submit issues or pull requests if you find bugs or have feature suggestions.

## License

MIT License - feel free to use and modify as needed.

## ⚠️ Important Warnings

**THIS MAY DELETE ALL OF YOUR APPLE NOTES. USE WITH EXTREME CARE!**

- **This worked for me, but may not work for you!** Test with a small folder first.
- **You WILL lose all creation dates on your Apple Notes.** The duplicated notes will have new creation timestamps.
- This is a scary process that involves recreating all your notes. Back up everything before proceeding.
- After using this tool successfully, I've gone a couple of weeks without disk space growth on iOS/iPad, so it appears to fix the issue.
- Always export or back up your Notes before using automation tools.
- While this script is designed to be non-destructive (it only creates copies), you'll need to delete the originals afterward to fix the disk space issue.

### How to Know If You Have This Issue

Check if iCloud reports a MUCH smaller disk space usage for Notes than Settings → General → Storage shows on your iOS/iPad device. This discrepancy indicates the disk space leak bug.
