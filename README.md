# Apple Notes Folder Duplicator

A utility tool for safely duplicating Apple Notes folders with all their contents.

## Description

This script creates a deep copy of an Apple Notes folder, duplicating all notes within it. The new folder is created with an asterisk suffix (e.g., "Test" becomes "Test*").

## Features

- Safe folder duplication using Apple's JXA (JavaScript for Automation)
- Preserves all note content and formatting
- Creates the duplicate in the same parent folder
- Comprehensive error handling and validation
- Prevents accidental overwrites

## Requirements

- macOS with Apple Notes installed
- JavaScript for Automation (JXA) - included with macOS

## Installation

1. Clone this repository or download the script
2. Make the script executable:

```bash
chmod +x duplicate-notes-folder.js
```

## Usage

Basic usage:

```bash
./duplicate-notes-folder.js "/ParentFolder/FolderName"
```

### Examples

Duplicate a folder called "Test" inside "Personal":

```bash
./duplicate-notes-folder.js "/Personal/Test"
```

This will create a new folder called "Test*" inside "Personal" with copies of all notes from "Test".

Duplicate a top-level folder:

```bash
./duplicate-notes-folder.js "/MyFolder"
```

### Path Format

- Use forward slashes to separate folder levels
- Start with a forward slash
- Example: "/ParentFolder/ChildFolder/TargetFolder"

## How It Works

1. The script parses the folder path you provide
2. It navigates through Apple Notes to find the target folder
3. It creates a new folder with the same name plus an asterisk (*)
4. It copies all notes from the source folder to the new folder
5. It preserves note names and content

## Safety Features

- Validates folder path before proceeding
- Checks if a folder with the duplicate name already exists
- Provides clear error messages if something goes wrong
- Does not modify or delete the original folder
- Does not access the Notes database directly (uses official Apple APIs)

## Limitations

- Currently duplicates notes within a single folder (not nested subfolders)
- Does not copy folder-specific metadata (like color or icon)
- Requires the source folder to exist in Apple Notes

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
- Grant the permission in System Preferences > Privacy & Security

## Technical Details

- Written in JXA (JavaScript for Automation)
- Uses Apple's official Notes.app scripting interface
- Safe and non-destructive operation
- No direct database manipulation

## Future Enhancements

Possible improvements for future versions:

- Support for nested subfolder duplication
- Custom naming for duplicated folders
- Progress bar for large folders
- Selective note copying (filter by criteria)
- Batch folder duplication

## Contributing

Feel free to submit issues or pull requests if you find bugs or have feature suggestions.

## License

MIT License - feel free to use and modify as needed.

## Warning

Always back up your Notes before using automation tools. While this script is designed to be safe and non-destructive, it's good practice to have backups of important data.
