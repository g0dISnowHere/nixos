# Orca Slicer Configuration Synchronization Plan

**Goal:** Synchronize Orca Slicer settings between Linux and Windows using Git versioning, directly capturing changes made via the Orca Slicer UI.

**Key Information:**
*   Orca Slicer stores configurations in `~/.config/OrcaSlicer` on Linux and `%APPDATA%\OrcaSlicer` on Windows.
*   The key configuration files to track are `OrcaSlicer.conf`, `printers/`, `system/`, and `user/`.
*   Files like `cache/`, `log/`, `ota/`, and `user_backup-*` should be ignored.

---

## Detailed Plan:

### Part 1: Linux Setup

1.  **Create a dedicated Git-managed directory for Orca Slicer configurations:**
    *   This directory will be created within your existing Git repository: `config_sync/orcaslicer`. This will be the central, version-controlled location for your Orca Slicer configurations.
    *   *Action to be performed by the agent:* `mkdir -p config_sync/orcaslicer`

2.  **User: Manually move existing Orca Slicer configuration files:**
    *   You (the user) will need to *move* the important Orca Slicer configuration files and directories from their current location (`~/.config/OrcaSlicer/`) into the newly created `config_sync/orcaslicer` directory.
    *   *Files/Directories to move:*
        *   `~/.config/OrcaSlicer/OrcaSlicer.conf`
        *   `~/.config/OrcaSlicer/printers/` (the entire directory)
        *   `~/.config/OrcaSlicer/system/` (the entire directory)
        *   `~/.config/OrcaSlicer/user/` (the entire directory)
    *   **Important:** Do *not* move `cache/`, `log/`, `ota/`, or any `user_backup-*` directories. These are temporary or dynamically generated and should remain in `~/.config/OrcaSlicer/` (or be allowed to be recreated by Orca Slicer).

3.  **Create Symbolic Links on Linux:**
    *   After you've moved the files, the agent will instruct you how to create symbolic links (`ln -s`) from the original `~/.config/OrcaSlicer/` paths to the files/directories now residing in `config_sync/orcaslicer`. This will allow Orca Slicer to continue reading from and writing to its standard location, while Git tracks the actual files in `config_sync/orcaslicer`.
    *   *Example command (for `OrcaSlicer.conf`):* `ln -s /home/djoolz/Documents/01_config/mine/config_sync/orcaslicer/OrcaSlicer.conf ~/.config/OrcaSlicer/OrcaSlicer.conf` (This will be done for each of the moved items).

4.  **Add `.gitignore` for Orca Slicer:**
    *   The agent will create a `.gitignore` file within `config_sync/orcaslicer` to explicitly ignore temporary or platform-specific files that might get created there, ensuring they are not committed to Git.
    *   *Content to add to `config_sync/orcaslicer/.gitignore`:*
        ```
        cache/
        log/
        ota/
        user_backup-*/
        ```

5.  **Initial Git Commit:**
    *   After the files are moved, symbolic links are created, and the `.gitignore` is in place, the agent will guide you to add and commit these changes to your Git repository.

### Part 2: Windows Setup

1.  **Clone the Git Repository:**
    *   On your Windows machine, you will need to clone your existing Git repository (e.g., `git clone <repo_url>`).

2.  **Create Symbolic Links on Windows:**
    *   You will need to use the `mklink` command (run in an **administrator command prompt**) to create symbolic links (junctions for directories, hard links for files) from Orca Slicer's expected Windows config location (`%APPDATA%\OrcaSlicer`) to the files/directories within your cloned `config_sync/orcaslicer` directory.
    *   *Example command (for `OrcaSlicer.conf`):* `mklink /H "%APPDATA%\OrcaSlicer\OrcaSlicer.conf" "C:\path	o\your
epo\config_sync\orcaslicer\OrcaSlicer.conf"`
    *   *Example command (for `printers` directory):* `mklink /J "%APPDATA%\OrcaSlicer\printers" "C:\path	o\your
epo\config_sync\orcaslicer\printers"`
    *   You will need to perform this for `OrcaSlicer.conf`, `printers/`, `system/`, and `user/`.

### Part 3: Synchronization Workflow

1.  **Making Changes:** Whenever you modify settings within the Orca Slicer UI on either Linux or Windows, the changes will be written directly to the files residing in your `config_sync/orcaslicer` directory (via the symbolic links).
2.  **Committing Changes:** After making changes, navigate to your Git repository, stage the changes (`git add config_sync/orcaslicer`), and commit them (`git commit -m "Updated Orca Slicer settings"`).
3.  **Push and Pull:**
    *   From the machine where you made changes, `git push` to upload them to your remote repository.
    *   On the other machine, `git pull` to download the latest configurations.
