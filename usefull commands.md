# show usefull error output when nixos-rebuild fails

```bash
sudo nixos-rebuild switch &>nixos-switch.log || (cat nixos-switch.log | grep --color error && exit 1)
```

# show usefull error output when nixos-rebuild fails, with more context

````bash
sudo nixos-rebuild switch &>nixos-switch.log || (echo "NixOS rebuild failed with the following error:" && cat nixos-switch.log | grep --color error && exit 1)
````

