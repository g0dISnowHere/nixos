# Hybrid Dotfile Management Plan

**Goal:** Implement a dotfile management strategy that combines the "live tracking" capability of a bare Git repository for frequently changing dotfiles with the declarative power of Home-Manager for other aspects of your user environment.

## Phase 1: Initial Setup and Preparation

1.  **Ensure `~/.local/bin` exists:** This directory is a common place for user-specific binaries and scripts, where we'll place our Git alias.
    ```bash
    mkdir -p ~/.local/bin
    ```

2.  **Identify Home-Manager Conflicts:** Before proceeding, if you have any `home.file` or `xdg.configFile` declarations in your Home-Manager config (e.g., in `flake/homes/djoolz.nix` or any modules it imports) that point to files you want to manage with the bare Git repo (e.g., `~/.bashrc`, `~/.config/nvim`), you will need to **comment them out or remove them** from your Home-Manager config. This is critical to avoid conflicts later.

## Phase 2: Set up the Bare Git Repository (`.cfg`)

1.  **Initialize Bare Git Repository:** Create a bare Git repository in your home directory, for example, `~/.cfg`. This repository will hold your dotfiles' history without placing a visible `.git` directory in your home folder.
    ```bash
    git init --bare $HOME/.cfg
    ```

2.  **Create `dotfiles` Alias/Function:** This makes it easy to run Git commands against your bare repository. We'll add this to a script in `~/.local/bin` and ensure your shell's `PATH` includes this directory.
    ```bash
    # Create the script
    echo '#!/bin/bash' > ~/.local/bin/dotfiles
    echo 'exec /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME "$@"' >> ~/.local/bin/dotfiles
    chmod +x ~/.local/bin/dotfiles

    # Add ~/.local/bin to your PATH (if not already) - add this to your .bashrc/.zshrc
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc # For Bash users
    # echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc # For Zsh users

    # Source your shell config to apply changes immediately
    source ~/.bashrc # or source ~/.zshrc
    ```
    *From now on, you can use `dotfiles` instead of `git` for commands related to your dotfiles.*

3.  **Configure Bare Repo to Hide Untracked Files:** This prevents `dotfiles status` from showing every file in your home directory, keeping the output clean and focused on your managed dotfiles.
    ```bash
    dotfiles config --local status.showUntrackedFiles no
    ```

## Phase 3: Populate the Bare Git Repository

1.  **Identify Initial Dotfiles to Track:** Decide which existing dotfiles you want to manage with this new bare Git repository. Start with a few simple ones like `~/.bashrc`, `~/.gitconfig`, or `~/.profile`.
2.  **Add to Git:** Use your new `dotfiles` command to stage these files.
    ```bash
    dotfiles add .bashrc .gitconfig .profile # Add all files you want to track
    ```
3.  **Initial Commit:**
    ```bash
    dotfiles commit -m "Initial commit of dotfiles managed by bare git repo"
    ```
4.  **Create `.gitignore` for the Bare Repo:** This is crucial. Create a `.gitignore` file directly in your home directory (`~/.gitignore`). This file will be managed by your bare Git repo and tell it to ignore files managed by Home-Manager (which create symlinks to the Nix store) and any other irrelevant files.
    ```bash
    # Create an initial .gitignore in your home directory
    # You will edit this file directly using your text editor
    touch ~/.gitignore

    # Add it to your bare Git repo
    dotfiles add .gitignore

    # Edit ~/.gitignore with necessary exclusions. Start with these:
    # .cfg/                      # The bare git repo itself
    # .local/bin/dotfiles        # The alias script
    # .config/home-manager       # Home-Manager's state directory
    # .local/state/home-manager  # Home-Manager's state directory
    # flake.nix                  # If home-manager is in your home dir directly
    # flake.lock                 # If home-manager is in your home dir directly
    # And any other paths that are symlinks to the Nix store or are managed by Home-Manager modules.
    ```
    *After editing `~/.gitignore`, make sure to `dotfiles commit -m "Add .gitignore"` it.*

## Phase 4: Integrate with Home-Manager (Concurrent Strategy)

1.  **Update Home-Manager Configuration:** Ensure your `home-manager` configuration (e.g., `flake/homes/djoolz.nix` and its imported modules) is set up to:
    *   **NOT manage** any of the dotfiles you are now tracking with your bare Git repository (by removing `home.file` declarations for them).
    *   **Leverage dedicated `home-manager` modules** (e.g., `programs.zsh.enable = true;`, `programs.git.enable = true;`) for other applications where you prefer declarative management. These modules will generate symlinked files that your bare Git repo's `.gitignore` should exclude.
2.  **Apply Home-Manager Configuration:**
    ```bash
    home-manager switch --flake .#djoolz@workstation # or your appropriate profile
    ```

## Phase 5: Ongoing Workflow

1.  **For Dotfiles Managed by Bare Git Repo:**
    *   Make changes directly in your home directory (e.g., edit `~/.bashrc`, change settings in PrusaSlicer's UI which writes to `~/.config/PrusaSlicer/config.ini`).
    *   Use `dotfiles status`, `dotfiles diff` to see the changes.
    *   Use `dotfiles add <file>` and `dotfiles commit -m "..."` to save your changes to Git.
2.  **For Configurations Managed by Home-Manager:**
    *   Edit your Nix configuration files (e.g., `flake/homes/djoolz.nix`, `modules/home/programs/zsh.nix`).
    *   Run `home-manager switch --flake .#djoolz@workstation` to apply those changes.
