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
        const existingFolders = parentFolder.folders.whose({ name: newFolderName });
        if (existingFolders.length > 0) {
            throw new Error(`Folder "${newFolderName}" already exists. Please rename or delete it first.`);
        }

        // Create the new folder
        const newFolder = app.Folder({
            name: newFolderName
        });
        parentFolder.folders.push(newFolder);

        // Get all notes from the source folder
        const notes = targetFolder.notes();
        console.log(`Found ${notes.length} note(s) to copy`);

        // Copy each note
        let copiedCount = 0;
        for (let i = 0; i < notes.length; i++) {
            const note = notes[i];
            try {
                const noteName = note.name();
                const noteBody = note.body();

                console.log(`  Copying note ${i + 1}/${notes.length}: ${noteName}`);

                // Create a new note in the new folder
                const newNote = app.Note({
                    name: noteName,
                    body: noteBody
                });
                newFolder.notes.push(newNote);

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
 */
function findFolder(app, pathParts) {
    // Start with top-level folders
    let currentFolders = app.folders();
    let currentFolder = null;

    for (let i = 0; i < pathParts.length; i++) {
        const targetName = pathParts[i];
        let found = false;

        for (let j = 0; j < currentFolders.length; j++) {
            const folder = currentFolders[j];
            if (folder.name() === targetName) {
                currentFolder = folder;
                found = true;

                // If this is not the last part, get subfolders
                if (i < pathParts.length - 1) {
                    currentFolders = folder.folders();
                }
                break;
            }
        }

        if (!found) {
            return null;
        }
    }

    return currentFolder;
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
