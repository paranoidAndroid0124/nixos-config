# NixOS Configuration

My personal NixOS configuration files.

## Files

- `configuration.nix` - Main system configuration
- `hardware-configuration.nix` - Hardware-specific configuration

## Usage

To apply this configuration:

```bash
sudo nixos-rebuild switch
```

To update the system:

```bash
sudo nixos-rebuild switch --upgrade
```
