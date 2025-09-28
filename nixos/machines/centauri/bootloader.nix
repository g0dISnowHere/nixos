{ config, pkgs, ... }:

{

  # Enable filesystem support for various formats
  boot.supportedFilesystems = [
    "ntfs" # Windows NTFS volumes
    "exfat" # Extended FAT (common on USB drives, SD cards)
    "f2fs" # Flash-Friendly File System (good for SSDs)
    "btrfs" # B-tree file system (advanced features, snapshots)
    # "zfs"       # ZFS file system (enterprise features, checksums)
    "xfs" # XFS file system (high performance)
  ];

  boot.kernelParams = [
    "nohz_full=2-7" # NixOS produces many wakeups per second, which is bad for battery life. This kernel parameter disables the timer tick on the last 6 cores
    "mitigations=off" # Disable all CPU mitigations (Spectre, Meltdown, etc.) FIXME dangerous.
  ];
}
