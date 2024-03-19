{
  lib,
  stdenv,
  bash,
  pinentry-curses,
  pinentry-gnome3,
  pinentry_mac,
  writeScriptBin,
  pinentryPackage ? if stdenv.hostPlatform.isDarwin then pinentry_mac else pinentry-gnome3,
}:

# use GUI pinentry (e.g. pinentry-gnome3) on desktop and pinentry-curses on ssh
# https://superuser.com/a/1761740
writeScriptBin "pinentry-wrapper" ''
  #!${lib.getExe bash}

  # set PINENTRY_USER_DATA since no other environment variables are read in pinentry
  # https://www.gnupg.org/documentation/manuals/gnupg/GPG-Configuration.html#index-PINENTRY_005fUSER_005fDATA
  if [ $PINENTRY_USER_DATA = "USE_CURSES" ]; then
    # set pinentry-curses explicitly since pinentry-mac does not have curses flavor
    ${lib.getExe pinentry-curses} "$@"
  else
    ${lib.getExe pinentryPackage} "$@"
  fi
''
