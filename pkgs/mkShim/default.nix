{
  lib,
  writeShellScriptBin,
  symlinkJoin,
}:

let
  mkShim =
    command: package:
    writeShellScriptBin command ''
      echo "Error: '${command}' command not found." >&2
      echo "Please install ${package} by adding it to your Nix configuration:" >&2
      echo "  environment.systemPackages = [ pkgs.${package} ];" >&2
      echo "or" >&2
      echo "  home.packages = [ pkgs.${package} ];" >&2
      exit 127
    '';

  commandLineToolsShim = symlinkJoin {
    name = "command-line-tools-shim";
    paths = [
      (mkShim "cc" "clang")
      (mkShim "c++" "clang")
      (mkShim "clang" "clang")
      (mkShim "clang++" "clang")
      (mkShim "gcc" "gcc")
      (mkShim "g++" "gcc")
      (mkShim "otool" "darwin.binutils")
      (mkShim "pip3" "python3")
      (mkShim "python3" "python3")
      (mkShim "strings" "darwin.binutils")
      (mkShim "xcodebuild" "xcbuild")
      (mkShim "xcrun" "xcbuild")
      # actool
      # agvtool
      # ar
      # as
      # asa
      # bison
      # bm4
      # c++filt
      # c89
      # c99
      # clangd
      # cmpdylib
      # codesign_allocate
      # cpp
      # ctags
      # ctf_insert
      # DeRez
      # desdp
      # dsymutil
      # dwarfdump
      # dyld_info
      # flex
      # flex++
      # gatherheaderdoc
      # gcov
      # genstrings
      # GetFileInfo
      # git
      # git-receive-pack
      # git-shell
      # git-upload-archive
      # git-upload-pack
      # gm4
      # gnumake
      # gperf
      # hdxml2manxml
      # headerdoc2html
      # ibtool
      # ictool
      # indent
      # install_name_tool
      # ld
      # lex
      # libtool
      # lipo
      # lldb
      # llvm-g++
      # llvm-gcc
      # lorder
      # m4
      # make
      # mig
      # nm
      # nmedit
      # objdump
      # opendiff
      # pagestuff
      # ranlib
      # ResMerger
      # resolveLinks
      # Rez
      # rpcgen
      # sdef
      # sdp
      # segedit
      # SetFile
      # size
      # sourcekit-lsp
      # SplitForks
      # stapler
      # strip
      # swift
      # swiftc
      # unifdef
      # unifdefall
      # vtool
      # xcdebug
      # xcscontrol
      # xcsdiagnose
      # xctrace
      # xed
      # xml2man
      # yacc
    ];
    meta = {
      description = "Command not found shims for command line tools";
      platforms = lib.platforms.darwin;
      priority = 10; # Lower priority to avoid conflicts
    };
  };
in
{
  inherit mkShim commandLineToolsShim;
}
