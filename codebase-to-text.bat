@echo off
REM ============================================
REM Script Name: codebase-to-text.bat
REM Description: Converts a structured codebase into a single TXT file.
REM Usage:
REM   codebase-to-text.bat <codebase_path> [--exclude \file1 \folder1\ ...] [--debug]
REM Example:
REM   codebase-to-text.bat D:\super-codebase --exclude \manifest.json \js\ \css\ --debug
REM ============================================

REM Enable delayed variable expansion for handling variables inside loops
SETLOCAL ENABLEDELAYEDEXPANSION

REM ============================
REM Initialization
REM ============================

SET "debug=0"
SET "exclude_list="

REM ============================
REM Argument Parsing and Validation
REM ============================

REM Check if at least one argument (codebase path) is provided
IF "%~1"=="" (
    ECHO(
    ECHO Usage: codebase-to-text.bat ^<codebase_path^> [--exclude \file1 \folder1\ ...] [--debug]
    ECHO Example: codebase-to-text.bat D:\super-codebase --exclude \manifest.json \js\ \css\ --debug
    ECHO(
    EXIT /B 1
)

SET "input_dir=%~1"

REM Remove any trailing backslash from input_dir
IF "%input_dir:~-1%"=="\" SET "input_dir=%input_dir:~0,-1%"

REM Verify that the input directory exists
IF NOT EXIST "%input_dir%" (
    ECHO(
    ECHO Error: The directory "%input_dir%" does not exist.
    ECHO(
    EXIT /B 1
)

REM ============================
REM Processing Arguments
REM ============================

SET "arg_index=2"
:process_args
    REM Check if we've processed all arguments
    CALL SET "current_arg=%%~%arg_index%%"
    IF NOT DEFINED current_arg GOTO after_args

    REM Check for options
    IF /I "%current_arg%"=="--exclude" (
        SET /A "arg_index+=1"
        GOTO read_excludes
    ) ELSE IF /I "%current_arg%"=="--debug" (
        SET "debug=1"
    ) ELSE (
        ECHO(
        ECHO Error: Unknown option "%current_arg%"
        ECHO(
        EXIT /B 1
    )
    SET /A "arg_index+=1"
    GOTO process_args

:read_excludes
    REM Read all remaining arguments as exclude files or folders
    :collect_excludes
        CALL SET "exclude_item=%%~%arg_index%%"
        IF NOT DEFINED exclude_item GOTO after_args
        REM Check if the exclude_item is another option
        IF /I "%exclude_item%"=="--debug" (
            SET "debug=1"
            SET /A "arg_index+=1"
            GOTO collect_excludes
        )
        ECHO "%exclude_item%" | FINDSTR /B /C:"--" >NUL
        IF "%ERRORLEVEL%"=="0" (
            ECHO(
            ECHO Error: Unexpected option "%exclude_item%" after --exclude
            ECHO(
            EXIT /B 1
        )
        SET "exclude_list=!exclude_list! !exclude_item!"
        SET /A "arg_index+=1"
        GOTO collect_excludes

:after_args

REM ============================
REM Setting Up the Output File
REM ============================

REM Define the output file path by appending .txt to the input directory
SET "output_file=%input_dir%.txt"

REM Delete the output file if it already exists to avoid appending to old content
IF EXIST "%output_file%" DEL "%output_file%"

REM ============================
REM Processing the Exclude List
REM ============================

REM Initialize variables to hold exclude files and folders
SET "exclude_files="
SET "exclude_folders="

REM If an exclude list is provided, categorize them into files and folders
IF NOT "%exclude_list%"=="" (
    FOR %%E IN (%exclude_list%) DO (
        SET "item=%%E"
        REM Ensure the item starts with a backslash
        IF "!item:~0,1!" NEQ "\" (
            ECHO(
            ECHO Error: Exclusion paths should start with a backslash: !item!
            ECHO(
            EXIT /B 1
        )
        REM Remove the leading backslash for consistency
        SET "item=!item:~1!"
        REM Check if item ends with backslash (folder)
        IF "!item:~-1!"=="\" (
            REM Remove trailing backslash
            SET "item=!item:~0,-1!"
            SET "exclude_folders=!exclude_folders! !item!"
        ) ELSE (
            SET "exclude_files=!exclude_files! !item!"
        )
    )
)

IF "%debug%"=="1" (
    ECHO Debug: Exclude Files: !exclude_files!
    ECHO Debug: Exclude Folders: !exclude_folders!
)

REM ============================
REM Including Folder Structure at the Top
REM ============================

REM Add header for the folder structure
(
    ECHO(
    ECHO ********** BELOW IS THE FILE AND FOLDER STRUCTURE OF THE CODEBASE **********
    ECHO(
) >> "%output_file%"

REM Use TREE command to list files and folders recursively
TREE "%input_dir%" /F /A >> "%output_file%"

REM ============================
REM Traversing and Processing Files
REM ============================

REM Iterate through all files in the input directory and its subdirectories
FOR /F "delims=" %%F IN ('DIR /A:-D /B /S "%input_dir%"') DO (
    REM Get the full path of the current file
    SET "full_path=%%F"

    REM Derive the relative path by removing the input directory path
    SET "relative_path=!full_path:%input_dir%\=!"
    REM Remove any leading backslash from relative_path
    IF "!relative_path:~0,1!"=="\" SET "relative_path=!relative_path:~1!"
    REM Normalize slashes to backslashes
    SET "relative_path=!relative_path:/=\!"

    REM Initialize the exclude flag for the current file
    SET "exclude=0"

    REM Check if the current file is in the exclude files list
    IF NOT "!exclude_files!"=="" (
        FOR %%X IN (!exclude_files!) DO (
            REM Perform a case-insensitive comparison
            IF /I "%%X"=="!relative_path!" (
                SET "exclude=1"
            )
        )
    )

    REM Check if the current file is under any excluded folders
    IF "!exclude!"=="0" IF NOT "!exclude_folders!"=="" (
        FOR %%D IN (!exclude_folders!) DO (
            REM Prepare exclude_folder
            SET "exclude_folder=%%D"
            REM Normalize slashes
            SET "exclude_folder=!exclude_folder:/=\!"
            REM Add a backslash to exclude_folder
            SET "exclude_folder=!exclude_folder!\"
            REM Add a backslash to relative_path
            SET "relative_path_with_bs=!relative_path!\"
            REM Check if relative_path_with_bs starts with exclude_folder
            CALL SET "modified_path=%%relative_path_with_bs:!exclude_folder!=%%"
            IF NOT "!modified_path!"=="!relative_path_with_bs!" (
                SET "exclude=1"
            )
        )
    )

    REM Output processing information
    IF "%debug%"=="1" (
        IF "!exclude!"=="1" (
            ECHO(
            ECHO Processing File: !relative_path! [EXCLUDED]
        ) ELSE (
            ECHO(
            ECHO Processing File: !relative_path!
        )
    )

    REM If the file is not excluded, process it
    IF "!exclude!"=="0" (
        REM Write the header to the output file
        (
            ECHO(
            ECHO ********** BELOW IS THE CONTENT OF FILE: \!relative_path! **********
            ECHO(
        )>>"%output_file%"

        REM Append the content of the current file to the output file
        TYPE "%%F" >>"%output_file%"

        REM Add an empty line for readability
        ECHO(>>"%output_file%"
    )
)

REM ============================
REM Completion Message
REM ============================

ECHO(
ECHO Conversion completed successfully!
ECHO Output File: "!output_file!"
ECHO(

REM End of script
ENDLOCAL
EXIT /B 0
