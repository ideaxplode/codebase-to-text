# Codebase to Text

Converts a structured codebase (folder structure with files) into a single text file. This is to make it easy to feed an entire codebase as context to LLMs and AI systems.

NOTE: This is a Python script that runs in the terminal.

## Description

**Codebase to Text** is a Python script that converts a structured codebase into a single text file by concatenating the contents of all files. It allows you to exclude specific files or folders and includes the entire folder and file structure at the top of the output file.

## Features

- **Single .TXT File**: Concatenates all files in a specified folder into a single .txt output file
- **Exclusions**: You can exclude certain files and folders from concatenation (e.g. images, libraries etc.) that are not relevant for an LLM to understand. The `.git` folder at the root will be excluded by default
- **File Headers**: Inserts file headers (file name with path) before inserting the file's code in the output file for LLMs to understand
- **Folder Tree**: Includes the entire folder and file structure tree of the codebase at the top of the output file -- for LLMs to understand the complete code structure
- **Debug Mode**: Provides a debug mode for troubleshooting

## Installation

1. Download and install Python (if not already installed)
2. Download the `codebase-to-text.py` script from this repository
3. Navigate to the downloaded directory in the terminal

## Usage

### Basic Command-line Syntax
```python
python codebase-to-text.py D:\projects\my-codebase
```
- Here, `D:\projects\my-codebase` is the path of the source folder (the codebase)
- This command will output `my-codebase.txt` in the same location as the source folder i.e. `D:\projects\my-codebase.txt`
- If the path contains spaces, please enclose it in double quotes e.g. `"D:\my projects\my codebase"`

### Exclude Files/Folders
You can exclude certain files and folders by using the `--exclude` argument:
```python
python codebase-to-text.py D:\projects\my-codebase --exclude images icons js\jquery.min.js css\bootstrap.css "js\custom script.js"
```
- Multiple exclusion paths should be space-separated
- In the above example, `images` and `icons` are folders
- All exclusion paths are relative to the source folder's root
- If a path contains spaces, please enclose it in double quotes

### Debug Mode
You can run the script in debug mode using the `--debug` argument:
```python
python codebase-to-text.py D:\projects\my-codebase --debug --exclude js\jquery.min.js
```
- Debug mode will allow you to see the running process
- It will also show which files are included/excluded in the output file
