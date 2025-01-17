
# MP4 Merger Without Reencoding

## Overview

The **MP4 Merger Without Reencoding** is a PowerShell script designed to combine multiple `.mp4` files into a single `.mp4` file without reencoding, ensuring that the process is fast and retains the original video quality. Additionally, it can convert `.mp4` files into `.ts` format as part of the merging process and includes features like timestamp adjustments for GoPro videos and interactive file management.

This script works in the folder where it is placed. The combined `.mp4` file will use the name of the folder being worked in.

## Features

- **Combine Without Reencoding:** Merges multiple `.mp4` files into a single `.mp4` file without any reencoding.
- **Convert and Merge:** Optionally converts `.mp4` files to `.ts` format using `FFmpeg` and merges them into a single `.mp4`.
- **Timestamp Adjustment:** Automatically adds 4 hours to the timestamps of GoPro files (names starting with `GH0*`).
- **Interactive File Selection:** Provides options to include or exclude files using a graphical file picker.
- **Custom Directories:** Allows setting custom input and output directories with default folder options.
- **Temporary File Cleanup:** Offers the choice to delete temporary `.ts` files after merging.

## Prerequisites

1. **PowerShell** (Version 5.1 or later).
2. **FFmpeg**:
   - Download and install FFmpeg from [FFmpeg.org](https://ffmpeg.org/).
   - Ensure FFmpeg is added to your system's PATH for command-line access.

## Installation

1. Clone the repository or download the script:
   ```bash
   git clone https://github.com/yourusername/MP4-Merger-Without-Reencoding.git
   cd MP4-Merger-Without-Reencoding
   ```

2. Ensure the script is executable:
   ```powershell
   Unblock-File -Path .\mp4_merger.ps1
   ```

## Usage

1. Open a PowerShell terminal and run the script:
   ```powershell
   ./mp4_merger.ps1
   ```

2. Follow the prompts:
   - Confirm or change the input and output folders.
   - Include or exclude specific files.
   - Adjust timestamps for GoPro files if applicable.

3. Upon completion, the merged `.mp4` file will be saved in the specified output directory, with the name of the folder being worked in.

## Example Workflow

1. Place `.mp4` files in a designated input folder.
2. Run the script and select the desired output directory (default is `./converted`).
3. The script will:
   - Merge `.mp4` files into a single `.mp4` without reencoding.
   - Optionally convert `.mp4` files to `.ts` and merge them.
   - Optionally delete the `.ts` files after merging.

## Options and Controls

- **y/n/d/q Prompts:** During folder selection or file operations, you can:
  - Press `y` to confirm.
  - Press `n` to decline or make changes.
  - Press `d` to reset to the default folder.
  - Press `q` to quit with confirmation.
- **File Picker:** Use the graphical interface to include or exclude files interactively.

## Troubleshooting

- Ensure FFmpeg is correctly installed and accessible via the command line.
- Run PowerShell as an administrator if permission issues arise.

## License

This project is licensed under the MIT License. Feel free to use, modify, and distribute the script. See the `LICENSE` file for details.

## Contributions

Contributions are welcome! Feel free to fork the repository and submit a pull request with improvements or fixes.

## Acknowledgments

Thanks to the [FFmpeg](https://ffmpeg.org/) community for providing an essential tool for multimedia handling.
