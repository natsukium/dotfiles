{
  services.skhd = {
    enable = true;
    skhdConfig = ''
      # launch application
      cmd - return : ~/Applications/Home\ Manager\ Apps/kitty.app/Contents/MacOS/kitty --single-instance -d ~ -o allow_remote_control=yes

      # focus window
      alt - h : yabai -m window --focus west
      alt - j : yabai -m window --focus south
      alt - k : yabai -m window --focus north
      alt - l : yabai -m window --focus east
      alt - p : yabai -m window --focus prev
      alt - n : yabai -m window --focus next

      # swap window
      shift + alt - h : yabai -m window --swap west
      shift + alt - j : yabai -m window --swap south
      shift + alt - k : yabai -m window --swap north
      shift + alt - l : yabai -m window --swap east

      # move window
      shift + cmd - h : yabai -m window --warp west
      shift + cmd - j : yabai -m window --warp south
      shift + cmd - k : yabai -m window --warp north
      shift + cmd - l : yabai -m window --warp east

      # focus desktop
      cmd + alt - 1 : yabai -m space --focus 1
      cmd + alt - 2 : yabai -m space --focus 2
      cmd + alt - 3 : yabai -m space --focus 3
      cmd + alt - 4 : yabai -m space --focus 4
      cmd + alt - 5 : yabai -m space --focus 5
      cmd + alt - 6 : yabai -m space --focus 6
      cmd + alt - 7 : yabai -m space --focus 7
      cmd + alt - 8 : yabai -m space --focus 8
      cmd + alt - 9 : yabai -m space --focus 9
      cmd + alt - 0 : yabai -m space --focus 10

      # resize
      shift + alt - a : yabai -m window --resize right:-100:0 || yabai -m window --resize left:-100:0
      shift + alt - s : yabai -m window --resize bottom:0:100 || yabai -m window --resize top:0:100
      shift + alt - w : yabai -m window --resize bottom:0:-100 || yabai -m window --resize top:0:-100
      shift + alt - d : yabai -m window --resize right:100:0 || yabai -m window --resize left:100:0
    '';
  };
}
