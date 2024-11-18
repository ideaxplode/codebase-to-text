#!/usr/bin/env python3

import os
import sys
import argparse

def parse_args():
    parser = argparse.ArgumentParser(
        description='Converts a structured codebase into a single TXT file.')
    parser.add_argument('codebase_path', help='Path to the codebase directory.')
    parser.add_argument('--exclude', nargs='*', default=[],
                        help='List of files and folders to exclude. Paths should start with \\ and folders end with \\')
    parser.add_argument('--debug', action='store_true',
                        help='Enable debug output.')
    return parser.parse_args()

def normalize_path(path):
    # Remove leading backslash
    if path.startswith('\\') or path.startswith('/'):
        path = path[1:]
    # Remove trailing backslash
    if path.endswith('\\') or path.endswith('/'):
        path = path[:-1]
    # Normalize slashes to backslashes
    path = path.replace('/', '\\')
    return path

def is_excluded(relative_path, exclude_files, exclude_folders):
    # Check if the file is in the exclude files list
    if relative_path in exclude_files:
        return True
    # Check if the file is under any excluded folders
    for folder in exclude_folders:
        if relative_path.startswith(folder):
            return True
    return False

def main():
    args = parse_args()
    input_dir = args.codebase_path

    if not os.path.isdir(input_dir):
        print(f"Error: The directory '{input_dir}' does not exist.")
        sys.exit(1)

    # Process the exclude list
    exclude_files = []
    exclude_folders = []

    # Exclude the .git folder in the root by default
    exclude_folders.append('.git\\')

    for item in args.exclude:
        if not (item.startswith('\\') or item.startswith('/')):
            print(f"Error: Exclusion paths should start with a backslash: {item}")
            sys.exit(1)
        item_normalized = normalize_path(item)
        # Check if it's a folder or file
        if item.endswith('\\') or item.endswith('/'):
            exclude_folders.append(item_normalized + '\\')
        else:
            exclude_files.append(item_normalized)

    if args.debug:
        print()  # Blank line before exclusion lists
        # Format the exclusion lists to display single backslashes
        exclude_files_str = ', '.join(exclude_files)
        exclude_folders_str = ', '.join(exclude_folders)
        print(f"Exclude Files: [{exclude_files_str}]")
        print(f"Exclude Folders: [{exclude_folders_str}]")
        print()  # Blank line after exclusion lists

    output_file = os.path.abspath(input_dir.rstrip(os.sep) + '.txt')
    if os.path.exists(output_file):
        os.remove(output_file)

    # Write folder structure to output file
    with open(output_file, 'w', encoding='utf-8') as outfile:
        outfile.write('\n')
        outfile.write('********** BELOW IS THE FILE AND FOLDER STRUCTURE OF THE CODEBASE **********\n')
        outfile.write('\n')
        # Generate the folder structure
        for root, dirs, files in os.walk(input_dir, topdown=True):
            # Exclude the .git folder from the folder tree
            dirs_to_process = []
            for d in dirs:
                if d == '.git':
                    continue  # Exclude .git silently
                dirs_to_process.append(d)
            dirs[:] = dirs_to_process

            level = root.replace(input_dir, '').count(os.sep)
            indent = ' ' * 4 * level
            folder_name = os.path.basename(root)
            outfile.write(f'{indent}{folder_name}/\n')
            subindent = ' ' * 4 * (level + 1)
            for f in files:
                outfile.write(f'{subindent}{f}\n')

    # Traverse and process files
    for root, dirs, files in os.walk(input_dir, topdown=True):
        # Exclude .git and specified folders from traversal
        dirs_to_process = []
        for d in dirs:
            if d == '.git':
                continue  # Exclude .git silently
            relative_dir = os.path.relpath(os.path.join(root, d), input_dir).replace('/', '\\')
            if is_excluded(relative_dir + '\\', [], exclude_folders):
                if args.debug:
                    print(f"Processing Folder: {relative_dir} [EXCLUDED]")
            else:
                dirs_to_process.append(d)
        dirs[:] = dirs_to_process

        for file in files:
            relative_path = os.path.relpath(os.path.join(root, file), input_dir).replace('/', '\\')
            excluded = is_excluded(relative_path, exclude_files, exclude_folders)
            if args.debug:
                if excluded:
                    print(f"Processing File: {relative_path} [EXCLUDED]")
                else:
                    print(f"Processing File: {relative_path}")
            if not excluded:
                with open(output_file, 'a', encoding='utf-8') as outfile:
                    # Ensure the previous content ends with a newline
                    outfile.write('\n')  # Blank line before the header
                    outfile.write(f'********** BELOW IS THE CONTENT OF FILE: \\{relative_path} **********\n')
                    outfile.write('\n')  # Blank line after the header
                    # Read the file and write its content
                    file_path = os.path.join(root, file)
                    try:
                        with open(file_path, 'r', encoding='utf-8', errors='ignore') as infile:
                            content = infile.read()
                            outfile.write(content)
                            # Ensure the file content ends with a newline
                            if not content.endswith('\n'):
                                outfile.write('\n')
                    except Exception as e:
                        print(f"Error reading file {file_path}: {e}")

    print('\nConversion completed successfully!')
    print(f'Output File: "{output_file}"\n')

if __name__ == '__main__':
    main()
