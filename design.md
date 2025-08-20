# Dotfiles Module Architecture Design

## Executive Summary

This document outlines a comprehensive redesign of the dotfiles repository structure to improve modularity, maintainability, and cross-platform compatibility. The proposed architecture introduces a clear separation between system-level and user-level configurations, with a unified module system that works across NixOS, Darwin, and home-manager.

## Table of Contents

1. [Current State Analysis](#current-state-analysis)
2. [Design Goals](#design-goals)
3. [Proposed Architecture](#proposed-architecture)
4. [Directory Structure](#directory-structure)
5. [Module System](#module-system)
6. [Layer Architecture](#layer-architecture)
7. [Profile System](#profile-system)
8. [Machine Configuration](#machine-configuration)
9. [Migration Strategy](#migration-strategy)
10. [Examples](#examples)

## Current State Analysis

### Current Structure

The repository currently has the following structure:

```
dotfiles/
├── applications/       # Direct program configurations (26+ apps)
├── modules/           # Custom NixOS/Darwin/home-manager modules
├── systems/           # System-level configurations by platform
├── homes/             # Home-manager configurations by platform
├── hosts/             # Machine-specific configurations
├── pkgs/              # Custom packages
├── overlays/          # Nixpkgs overlays
└── infra/             # Infrastructure as code
```

### Issues Identified

1. **Fragmentation**: Configuration logic is scattered across multiple directories
2. **Unclear boundaries**: No clear distinction between what belongs in `applications/` vs `modules/`
3. **Duplication**: Similar configurations repeated across platforms
4. **Limited reusability**: Difficult to compose configurations for different use cases
5. **Platform coupling**: Platform-specific code mixed with generic configurations

## Design Goals

1. **Clear separation of concerns**: Distinct layers for different configuration levels
2. **Maximum reusability**: Modular components that can be easily composed
3. **Platform transparency**: Write once, run on any supported platform
4. **Type safety**: Leverage Nix's type system for configuration validation
5. **Progressive disclosure**: Simple defaults with advanced customization options
6. **Machine-aware**: Adapt configurations based on hardware capabilities
7. **Profile-based**: Pre-defined configuration sets for common use cases

## Proposed Architecture

### 4-Layer Architecture

```
┌─────────────────────────────────────┐
│         Profile Layer               │  ← User-facing presets
├─────────────────────────────────────┤
│         Home Layer                  │  ← User environment (home-manager)
├─────────────────────────────────────┤
│         System Layer                │  ← OS-level (NixOS/Darwin)
├─────────────────────────────────────┤
│         Shared Layer                │  ← Common utilities and libraries
└─────────────────────────────────────┘
```

Each layer has specific responsibilities and can only depend on layers below it.

## Directory Structure

```
modules/
├── lib/                    # Shared libraries and helpers
│   ├── assertions.nix      # Common assertion helpers
│   ├── mkModule.nix        # Module creation utilities
│   ├── mkService.nix       # Cross-platform service abstraction
│   └── platform.nix        # Platform detection and helpers
│
├── shared/                 # Platform-agnostic configurations
│   ├── nix/               # Nix daemon configuration
│   │   ├── default.nix    # Common Nix settings (includes optimise)
│   │   ├── flakes.nix     # Flakes configuration
│   │   └── cachix.nix     # Binary cache settings
│   └── packages/          # Common package sets
│       ├── base.nix       # Essential packages
│       ├── development.nix # Development tools
│       └── desktop.nix    # Desktop applications
│
├── nixos/                  # NixOS system-level configurations
│   ├── boot/              # Boot loader configuration
│   ├── hardware/          # Hardware enablement
│   ├── services/          # System services
│   └── desktop/           # Desktop environments
│
├── darwin/                 # macOS system-level configurations
│   ├── system/            # System preferences
│   ├── services/          # launchd services
│   └── homebrew/          # Homebrew integration
│
├── home/                   # User-level configurations (home-manager)
│   ├── nix/               # Home-manager specific Nix settings (XDG)
│   ├── terminal/          # Terminal environment
│   │   ├── emulators/     # Terminal emulators
│   │   ├── shells/        # Shell configurations
│   │   ├── prompts/       # Prompt themes
│   │   └── multiplexers/  # Terminal multiplexers
│   ├── editors/           # Text editors
│   ├── development/       # Development tools
│   └── desktop/           # Desktop applications
│
├── profiles/              # Configuration profiles (user entry points)
│   ├── nixos/             # NixOS profiles
│   │   ├── base.nix       # Minimal NixOS configuration
│   │   ├── desktop.nix    # Desktop user profile
│   │   ├── developer.nix  # Developer profile
│   │   └── server.nix     # Server profile
│   ├── darwin/            # macOS profiles
│   │   ├── base.nix       # Minimal Darwin configuration
│   │   ├── desktop.nix    # Desktop user profile
│   │   └── developer.nix  # Developer profile
│   └── home/              # Home-manager profiles
│       ├── base.nix       # Minimal home configuration
│       ├── desktop.nix    # Desktop user profile
│       └── developer.nix  # Developer profile
│
├── nixos-modules/         # Generic NixOS modules (upstream-ready)
│   └── ...                # Modules suitable for upstream contribution
│
├── darwin-modules/        # Generic Darwin modules (upstream-ready)
│   └── ...                # Modules suitable for upstream contribution
│
└── home-manager-modules/          # Generic home-manager modules (upstream-ready)
    └── ...                # Modules suitable for upstream contribution
```

## Module System

### Option Namespace

All custom options are organized under the `my` namespace to avoid conflicts with upstream modules. The `*-modules` directories contain generic, reusable modules that can be contributed upstream and are exported as Flake outputs:

```nix
{
  my = {
    # System-level options
    system = {
      networking = { ... };
      services = { ... };
    };

    # Home-manager options
    home = {
      terminal = { ... };
      editors = { ... };
      development = { ... };
    };

    # Machine metadata
    machine = {
      name = "hostname";
      type = "laptop" | "desktop" | "server" | "vm";
      hardware = { ... };
    };

    # Platform detection
    platform = "nixos" | "darwin" | "linux" | "wsl";
  };
}
```

### Flake Outputs Alignment

The `*-modules` directories are designed to align with standard Flake outputs:

```nix
# flake.nix
{
  outputs = { self, ... }: {
    # Generic modules for distribution
    nixosModules = ./modules/nixos-modules;
    darwinModules = ./modules/darwin-modules;
    homeManagerModules = ./modules/home-manager-modules;

    # Custom configurations
    nixosConfigurations = { ... };
    darwinConfigurations = { ... };
    homeConfigurations = { ... };
  };
}
```

### Module Definition Pattern

```nix
# modules/home/terminal/emulators/alacritty.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.my.home.terminal.alacritty;
in
{
  options.my.home.terminal.alacritty = {
    enable = lib.mkEnableOption "Alacritty terminal emulator";
    
    fontSize = lib.mkOption {
      type = lib.types.int;
      default = 12;
      description = "Font size for Alacritty";
    };
    
    theme = lib.mkOption {
      type = lib.types.str;
      default = "nord";
      description = "Color theme";
    };
  };
  
  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        font.size = cfg.fontSize;
        # Platform-specific adjustments
        window = lib.mkMerge [
          { opacity = 0.95; }
          (lib.mkIf pkgs.stdenv.isDarwin {
            decorations = "buttonless";
          })
        ];
      };
    };
  };
}
```

## Layer Architecture

### Shared Layer

Platform-agnostic configurations and utilities that can be used by any layer above.

```nix
# modules/shared/nix/default.nix
{ config, lib, ... }:
{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "@wheel" ];
      auto-optimise-store = true;
    };
    
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
```

### System Layer

OS-level configurations that require system privileges.

```nix
# modules/system/nixos/services/docker.nix
{ config, lib, ... }:
let
  cfg = config.my.system.services.docker;
in
{
  options.my.system.services.docker = {
    enable = lib.mkEnableOption "Docker container runtime";
    
    enableNvidia = lib.mkOption {
      type = lib.types.bool;
      default = config.my.machine.hardware.gpu == "nvidia";
      description = "Enable NVIDIA GPU support";
    };
  };
  
  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      enableNvidia = cfg.enableNvidia;
    };
    
    users.users.${config.my.username}.extraGroups = [ "docker" ];
  };
}
```

### Home Layer

User-level configurations managed by home-manager.

```nix
# modules/home/development/git.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.my.home.development.git;
in
{
  options.my.home.development.git = {
    enable = lib.mkEnableOption "Git version control";
    
    userName = lib.mkOption {
      type = lib.types.str;
      description = "Git user name";
    };
    
    userEmail = lib.mkOption {
      type = lib.types.str;
      description = "Git user email";
    };
    
    signing = {
      enable = lib.mkEnableOption "GPG signing";
      key = lib.mkOption {
        type = lib.types.str;
        description = "GPG key ID";
      };
    };
  };
  
  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      userName = cfg.userName;
      userEmail = cfg.userEmail;
      
      signing = lib.mkIf cfg.signing.enable {
        key = cfg.signing.key;
        signByDefault = true;
      };
      
      # Platform-specific configurations
      extraConfig = {
        core.editor = "nvim";
        init.defaultBranch = "main";
        # macOS-specific keychain integration
        credential = lib.mkIf pkgs.stdenv.isDarwin {
          helper = "osxkeychain";
        };
      };
    };
  };
}
```

## Profile System

Profiles are platform-specific entry points that compose various modules to create ready-to-use configurations. They are organized by platform (NixOS, Darwin, home-manager) rather than by role/machine, simplifying the structure while maintaining flexibility.

### Platform-Specific Profiles

#### NixOS Profile Example

```nix
# modules/profiles/nixos/base.nix
{ config, lib, pkgs, ... }:
{
  imports = [ ../../shared/nix ];

  my.nix = {
    enable = true;
    enableFlakes = true;
  };

  nix.optimise.automatic = true;
}
```

```nix
# modules/profiles/nixos/developer.nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./base.nix  # Include base configuration
    ../../nixos/services/docker.nix
    ../../nixos/development
  ];

  my.system.services = {
    docker.enable = true;
    podman.enable = false;
  };
  
  # Additional developer-specific system settings
}
```

#### Darwin Profile Example

```nix
# modules/profiles/darwin/base.nix
{ config, lib, pkgs, ... }:
{
  imports = [ ../../shared/nix ];

  my.nix = {
    enable = true;
    enableFlakes = true;
  };

  nix.optimise.automatic = true;
}
```

#### Home-Manager Profile Example

```nix
# modules/profiles/home/base.nix
{ config, lib, pkgs, ... }:
{
  imports = [ ../../home/nix ];

  # Basic home-manager configuration
  # XDG settings handled by home/nix/default.nix
}
```

```nix
# modules/profiles/home/developer.nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./base.nix
    ../../home/development/git.nix
    ../../home/editors/neovim.nix
    ../../home/terminal/shells/fish.nix
  ];

  my.home = {
    development = {
      git = {
        enable = true;
        userName = "John Doe";
        userEmail = "john@example.com";
      };

      direnv.enable = true;

      languages = {
        rust.enable = true;
        python.enable = true;
        node.enable = true;
      };
    };

    editors = {
      neovim = {
        enable = true;
        variant = "full";
      };
      vscode.enable = true;
    };

    terminal = {
      shell = "fish";
      multiplexer = "tmux";
    };
  };
}
```

### Machine-Specific Configurations

Machine-specific settings (hardware optimizations, display configurations, etc.) are not abstracted into modules but remain in the individual machine configurations under `hosts/`. This keeps hardware-specific details close to where they're used.

```nix
# hosts/nixos/my-laptop/configuration.nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/profiles/nixos/developer.nix
  ];

  # Machine-specific hardware optimizations
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
  };

  # Machine-specific display settings
  services.xserver.dpi = 144;  # HiDPI for this specific laptop

  # Override profile defaults if needed
  my.home.terminal.fontSize = 14;  # Larger font for HiDPI
}
```

## Machine Configuration

Individual machine configurations import appropriate platform profiles and add machine-specific settings.

```nix
# hosts/nixos/desktop-ryzen/configuration.nix
{ config, pkgs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/profiles/nixos/developer.nix  # Platform-specific profile
  ];
  
  # Machine-specific hardware configuration
  boot.kernelModules = [ "kvm-amd" ];

  hardware = {
    cpu.amd.updateMicrocode = true;
    nvidia.modesetting.enable = true;
  };

  # Machine-specific services
  services = {
    xserver.videoDrivers = [ "nvidia" ];
  };
  
  # Override profile defaults
  my.system = {
    desktop = "niri";  # Choose window manager
    
    services = {
      # Enable CUDA support for machine learning
      cuda.enable = true;
      
      # Gaming-related services
      steam.enable = true;
    };
  };
  
  # Machine-specific home configuration
  home-manager.users.${config.my.username} = {
    imports = [
      ../../../modules/profiles/home/developer.nix
    ];

    my.home = {
      # Use larger fonts on dual-monitor setup
      terminal.fontSize = 14;

      # Additional development tools for ML
      development.languages.python.packages = [
        "tensorflow"
        "pytorch"
        "jupyter"
      ];
    };
  };
}
```

```nix
# hosts/darwin/macbook/configuration.nix
{ config, pkgs, lib, ... }:
{
  imports = [
    ../../../modules/profiles/darwin/developer.nix
  ];

  # Machine-specific macOS settings
  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    trackpad.Clicking = true;
  };

  # Machine-specific homebrew casks
  homebrew.casks = [
    "rectangle"
    "raycast"
  ];

  # Home-manager configuration
  home-manager.users.${config.my.username} = {
    imports = [
      ../../../modules/profiles/home/developer.nix
    ];

    # macOS-specific home settings
    my.home.terminal.fontSize = 13;
  };
}
```

## Secret Management

This architecture uses [sops-nix](https://github.com/Mic92/sops-nix) for managing secrets like API keys and passwords securely. Secrets are encrypted and stored directly in the repository, and decrypted on-the-fly during system evaluation.

### Directory Structure for Secrets

To maintain consistency with the layer architecture, secrets are organized in a parallel structure under the `secrets/` directory:

```
secrets/
├── shared/                  # Secrets common to all machines
│   └── main.yaml
├── system/
│   ├── common.yaml          # Common system-level secrets
│   └── nixos/
│       └── services.yaml    # Secrets for specific NixOS services
├── home/
│   ├── common.yaml          # Common user-level secrets (e.g., API keys)
│   └── roles/
│       └── developer.yaml   # Secrets used by the developer profile
└── machines/
    ├── my-laptop.yaml       # Secrets that can only be decrypted on a specific machine
    └── my-server.yaml
```

### Usage

- Secrets are defined in the `flake.nix` using the `sops.secrets` option, pointing to the encrypted files.
- Modules and profiles can then access the decrypted secret paths via `config.sops.secrets.<secret_name>.path`.
- The `.sops.yaml` file at the root of the repository controls which keys (e.g., GPG keys of users, age keys of hosts) can decrypt which files, ensuring proper access control.

This approach keeps secret management aligned with the overall design goals of clarity and separation of concerns.

## Migration Strategy

### Phase 1: Structure Creation (Week 1)
1. Create new directory structure under `modules/`
2. Set up base module infrastructure (`lib/`)
3. Create platform-specific profile directories

### Phase 2: Module Migration (Weeks 2-3)
1. Migrate existing `applications/` to `modules/home/`
2. Convert direct configurations to option-based modules
3. Extract platform-specific code to appropriate layers

### Phase 3: System Integration (Week 4)
1. Update import paths in existing configurations
2. Update machine configurations to use new profiles
3. Test on representative systems

### Phase 4: Cleanup (Week 5)
1. Remove old directory structures
2. Update documentation
3. Optimize module dependencies

### Rollback Plan
- Keep old structure in `legacy/` branch
- Maintain compatibility layer during migration
- Gradual opt-in for new module system

## Examples

### Example 1: Adding a New Application

To add a new terminal emulator (e.g., WezTerm):

```nix
# modules/home/terminal/emulators/wezterm.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.my.home.terminal.wezterm;
in
{
  options.my.home.terminal.wezterm = {
    enable = lib.mkEnableOption "WezTerm terminal emulator";
    
    fontSize = lib.mkOption {
      type = lib.types.int;
      default = config.my.home.terminal.fontSize or 12;
    };
  };
  
  config = lib.mkIf cfg.enable {
    programs.wezterm = {
      enable = true;
      extraConfig = ''
        return {
          font_size = ${toString cfg.fontSize},
          color_scheme = "${config.my.theme}",
        }
      '';
    };
  };
}
```

### Example 2: Cross-Platform Service

Creating a service that works on both NixOS and Darwin:

```nix
# modules/lib/mkService.nix
{ lib, pkgs, ... }:
{
  mkService = name: cfg:
    if pkgs.stdenv.isLinux then {
      systemd.user.services.${name} = {
        Unit = cfg.description;
        Service = {
          ExecStart = cfg.command;
          Restart = "on-failure";
        };
        Install.WantedBy = [ "default.target" ];
      };
    } else if pkgs.stdenv.isDarwin then {
      launchd.agents.${name} = {
        enable = true;
        config = {
          ProgramArguments = lib.splitString " " cfg.command;
          RunAtLoad = true;
          KeepAlive = true;
        };
      };
    } else
      throw "Unsupported platform for service ${name}";
}
```

### Example 3: Using Platform-Specific Profiles

```nix
# Using profiles in system configuration
# systems/common.nix
{ config, lib, pkgs, ... }:
{
  imports = [
    # Platform detection and appropriate profile import
    (if pkgs.stdenv.isLinux
     then ../modules/profiles/nixos/base.nix
     else ../modules/profiles/darwin/base.nix)
  ];
}

# Or directly in machine configuration
# hosts/nixos/my-machine/configuration.nix
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/profiles/nixos/developer.nix
  ];
}

# homes/common.nix
{
  imports = [
    ../modules/profiles/home/base.nix
  ];
}
```

## Benefits

### Improved Maintainability
- Clear separation of concerns
- Reduced code duplication
- Easier to locate and modify configurations

### Enhanced Reusability
- Modular components can be mixed and matched
- Profiles provide ready-to-use configurations
- Easy to share modules between machines

### Better Testing
- Each module can be tested independently
- Type checking ensures configuration validity
- Assertions prevent invalid combinations
- Platform-specific profiles ensure correct settings per OS

### Simplified Onboarding
- New machines can be set up quickly using platform-specific profiles
- Clear separation between NixOS, Darwin, and home-manager configurations
- Documentation is colocated with modules
- Progressive disclosure of complexity

## Conclusion

This architecture provides a solid foundation for managing complex multi-platform configurations while maintaining simplicity for common use cases. The layered approach ensures proper separation of concerns, while the profile system enables quick setup of new machines with minimal configuration.

The migration can be done incrementally, allowing for testing and refinement along the way. The end result will be a more maintainable, flexible, and powerful dotfiles repository that can grow with changing needs.
