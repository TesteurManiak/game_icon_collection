# How to add 3DS game icon to this repo?

1. Get your 3DS rom files ready. They'll need to be in `.3ds` or `.cci` format. If you have `.zcci`, `.z3ds`, `.cia`, or `.app`, you will have to convert them into one of these two formats.
2. Install [Python](https://www.python.org/downloads/) if you don't already have it.
3. Install the required Python dependencies by running the following command in a terminal:
   ```
   pip install pyctr Pillow
   ```
4. **If you already know how to fork a repository and contribute to the original, you can skip to step 5.** If you don't know how to do that, here's the process:
   * Download [GitHub Desktop](https://desktop.github.com/download)
   * Sign into GitHub Desktop with your GitHub account (if you don't have one, create one)
   * Clone the repository from URL, then navigate to wherever it saves the folder in your file explorer
5. Navigate to `contributing/n3ds/`, you should see a folder named `games`.
6. Put all your 3DS rom files here
7. Run one of the following scripts depending on your operating system:
   * Windows: `generate_icons.bat`
   * Linux/macOS: `generate_icons.sh`
8. The script will automatically extract the icons and move them to the proper location.
9. Once it's done, click the "commit to main" button in GitHub Desktop, to upload your changes to your forked repository.