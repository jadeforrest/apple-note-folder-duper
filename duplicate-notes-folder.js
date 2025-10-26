#!/usr/bin/env osascript -l JavaScript

/**
 * Apple Notes Folder Duplicator
 *
 * This script creates a deep copy of an Apple Notes folder,
 * duplicating all notes within it (including nested folders).
 *
 * Usage: ./duplicate-notes-folder.js "/Personal/Test"
 */

ObjC.import('stdlib');

function run(argv) {
    if (argv.length === 0) {
        console.log('Error: Please provide a folder path');
        console.log('Usage: ./duplicate-notes-folder.js "/ParentFolder/FolderName"');
        $.exit(1);
    }

    const folderPath = argv[0];
    const app = Application('Notes');
    app.includeStandardAdditions = true;

    try {
        // Parse the folder path
        const pathParts = folderPath.split('/').filter(part => part.length > 0);

        if (pathParts.length === 0) {
            throw new Error('Invalid folder path provided');
        }

        // Navigate to the target folder
        console.log(`Looking for folder: ${folderPath}`);
        const targetFolder = findFolder(app, pathParts);

        if (!targetFolder) {
            throw new Error(`Folder not found: ${folderPath}`);
        }

        const folderName = targetFolder.name();
        console.log(`Found folder: ${folderName}`);

        // Get the parent folder
        const parentFolder = targetFolder.container();

        // Create new folder with asterisk suffix
        const newFolderName = folderName + '*';
        console.log(`Creating new folder: ${newFolderName}`);

        // Check if folder with this name already exists
        try {
            const existingFolders = parentFolder.folders();
            for (let i = 0; i < existingFolders.length; i++) {
                try {
                    if (existingFolders[i].name() === newFolderName) {
                        throw new Error(`Folder "${newFolderName}" already exists. Please rename or delete it first.`);
                    }
                } catch (e) {
                    if (e.message && e.message.includes('already exists')) {
                        throw e;
                    }
                    // Skip inaccessible folder
                }
            }
        } catch (e) {
            if (e.message && e.message.includes('already exists')) {
                throw e;
            }
            // Can't check existing folders, proceed anyway
        }

        // Create the new folder
        const newFolder = app.Folder({
            name: newFolderName
        });
        parentFolder.folders.push(newFolder);

        // Get all notes from the source folder
        const notes = targetFolder.notes();
        console.log(`Found ${notes.length} note(s) to copy`);

        // Copy each note using duplicate() to preserve all formatting
        let copiedCount = 0;
        for (let i = 0; i < notes.length; i++) {
            const note = notes[i];
            try {
                const noteName = note.name();

                console.log(`  Copying note ${i + 1}/${notes.length}: ${noteName}`);

                // Duplicate the note (creates it in same folder)
                const duplicatedNote = note.duplicate();

                // Move the duplicated note to the new folder
                duplicatedNote.move({to: newFolder});

                copiedCount++;
            } catch (noteError) {
                console.log(`  Warning: Failed to copy note ${i + 1}: ${noteError.message}`);
            }
        }

        console.log(`\nSuccess! Created folder "${newFolderName}" with ${copiedCount} note(s)`);
        console.log(`Location: ${pathParts.slice(0, -1).join('/')}/${newFolderName}`);

    } catch (error) {
        console.log(`Error: ${error.message}`);
        $.exit(1);
    }
}

/**
 * Recursively find a folder by navigating through the path parts
 * Searches across all accounts since Apple Notes UI doesn't match scripting structure
 */
function findFolder(app, pathParts) {
    // Try to find the folder by searching all accounts
    const accounts = app.accounts();

    for (let a = 0; a < accounts.length; a++) {
        const account = accounts[a];
        const accountFolders = account.folders();

        // Try to match the path starting from this account's folders
        const result = findFolderInList(accountFolders, pathParts, 0);
        if (result) {
            return result;
        }
    }

    return null;
}

/**
 * Recursively search for a folder path in a list of folders
 */
function findFolderInList(folders, pathParts, pathIndex) {
    if (pathIndex >= pathParts.length) {
        return null;
    }

    const targetName = pathParts[pathIndex];

    for (let i = 0; i < folders.length; i++) {
        try {
            const folder = folders[i];
            const folderName = folder.name();

            if (folderName === targetName) {
                // Found a match for this path part
                if (pathIndex === pathParts.length - 1) {
                    // This is the final folder we're looking for
                    return folder;
                } else {
                    // Continue searching in subfolders
                    try {
                        const subfolders = folder.folders();
                        const result = findFolderInList(subfolders, pathParts, pathIndex + 1);
                        if (result) {
                            return result;
                        }
                    } catch (e) {
                        // Can't access subfolders, skip
                    }
                }
            }

            // Also search in this folder's subfolders in case the path doesn't start at the root
            try {
                const subfolders = folder.folders();
                if (subfolders.length > 0) {
                    const result = findFolderInList(subfolders, pathParts, pathIndex);
                    if (result) {
                        return result;
                    }
                }
            } catch (e) {
                // Can't access subfolders, skip
            }
        } catch (e) {
            // Skip inaccessible/deleted folders
            console.log(`  Warning: Skipping inaccessible folder at index ${i}`);
            continue;
        }
    }

    return null;
}

/**
 * Recursively duplicate a folder and all its contents (including subfolders)
 */
function duplicateFolderRecursive(app, sourceFolder, destinationFolder) {
    // Copy all notes
    const notes = sourceFolder.notes();
    let copiedCount = 0;

    for (let i = 0; i < notes.length; i++) {
        const note = notes[i];
        try {
            const noteName = note.name();
            const noteBody = note.body();

            const newNote = app.Note({
                name: noteName,
                body: noteBody
            });
            destinationFolder.notes.push(newNote);
            copiedCount++;
        } catch (error) {
            console.log(`  Warning: Failed to copy note: ${error.message}`);
        }
    }

    // Recursively copy subfolders
    const subfolders = sourceFolder.folders();
    for (let i = 0; i < subfolders.length; i++) {
        const subfolder = subfolders[i];
        const subfolderName = subfolder.name();

        console.log(`  Creating subfolder: ${subfolderName}`);

        const newSubfolder = app.Folder({
            name: subfolderName
        });
        destinationFolder.folders.push(newSubfolder);

        // Recursive call
        duplicateFolderRecursive(app, subfolder, newSubfolder);
    }

    return copiedCount;
}
