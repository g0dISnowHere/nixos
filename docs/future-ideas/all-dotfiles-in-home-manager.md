# Plan to Manage Your `~/.config/` Dotfiles with Home Manager

This plan outlines the steps to manage all files and directories within your `~/.config/` directory using Home Manager.

1.  **Create a Source Directory for Your Dotfiles:**
    *   We'll designate a directory within your Nix configuration to store the source of your dotfiles.
    *   A directory named `dotfiles` will be created inside your `mine` directory: `/home/djoolz/Documents/01_config/mine/dotfiles/`.
    *   Inside this `dotfiles` directory, a `.config` subdirectory will be created: `/home/djoolz/Documents/01_config/mine/dotfiles/.config/`. This is where your actual configuration files will reside.

2.  **Move Your Existing Dotfiles:**
    *   You will need to move the *entire contents* of your current `~/.config/` directory (from `/home/djoolz/.config/`) into the newly created `/home/djoolz/Documents/01_config/mine/dotfiles/.config/` directory.
    *   **Important:** After moving the files, your original `~/.config/` directory should ideally be empty (or backed up and then emptied). Home Manager will take over managing its contents.

3.  **Update `home.nix`:**
    *   An entry will be added to your `/home/djoolz/Documents/01_config/mine/nixos/home.nix` file. This entry tells Home Manager to manage your `~/.config/` directory by linking it to the source created in step 1.
    *   The configuration to be added is:

        ```nix
        # In mine/nixos/home.nix
        home.file.".config" = {
          source = ../dotfiles/.config; # Path relative to home.nix
          recursive = true;         # Links the entire directory recursively
        };
        ```

4.  **How It Works:**
    *   Home Manager will create symbolic links from your actual home directory (e.g., `/home/djoolz/.config/some_application_config`) to the corresponding files in your Nix configuration (e.g., `/home/djoolz/Documents/01_config/mine/dotfiles/.config/some_application_config`).
    *   This approach allows you to version control your dotfiles as part of your NixOS configuration.

5.  **Important Considerations:**
    *   **Collisions:** If there are existing files in `/home/djoolz/.config/` when you run `home-manager switch` for the first time after making these changes, Home Manager will report a collision (e.g., "Existing file '/home/jdoe/.config/git/config' is in the way") and will not overwrite them. This is why moving your files out of the original `~/.config/` (Step 2) is important before applying the Home Manager configuration.
    *   **Permissions:** Files linked this way are typically read-only by default. If any of your dotfiles need to be executable, the configuration for those specific files might need adjustment (e.g., by adding `executable = true;`). For most configuration files, this is not an issue.

**Visual Overview of the Proposed Structure:**

```mermaid
graph TD
    A["User's Home Directory (/home/djoolz)"] --- B["~/.config/ (Target, managed by Home Manager)"];
    C["Nix Configuration Project (/home/djoolz/Documents/01_config)"] --- D["mine/"];
    D --- E["nixos/"];
    E --- F["home.nix (references the source)"];
    D --- G["dotfiles/ (New directory for dotfile sources)"];
    G --- H[".config/ (Source: contains actual dotfile content)"];
    F -- "home.file '.config' links to<br/>../dotfiles/.config<br/>(recursive)" --> H;
    B -- "Symbolic links created by Home Manager" --> H;