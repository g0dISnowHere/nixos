# Just some useful commands

I use often, to avoid having to search for them in the terminal history or in the documentation.

## show usefull error output when nixos-rebuild fails

```bash
sudo nixos-rebuild switch &>nixos-switch.log || (cat nixos-switch.log | grep --color error && exit 1)
```

## show usefull error output when nixos-rebuild fails, with more context

````bash
sudo nixos-rebuild switch &>nixos-switch.log || (echo "NixOS rebuild failed with the following error:" && cat nixos-switch.log | grep --color error && exit 1)
````

## rollback

```bash
sudo nixos-rebuild switch --flake .# --rollback  
```

## list generated system generations

```bash
sudo nixos-rebuild list-generations
```

## update dconf.nix

```bash
dconf dump / | dconf2nix > modules/home/dconf/dconf.nix
```

## Check if D-Bus activation file exists

```bash
find /nix/store -path "*/share/dbus-1/services/*kdeconnect*" 2>/dev/null
```

## See recent system updates

```bash
nix profile diff-closures --profile /nix/var/nix/profiles/system | tail -n 50
```
