{ lib, ... }:
with lib; {
  flattenAttrsNames =
    let
      recurse =
        path: value:
        if isAttrs value && !isDerivation value then
          mapAttrsToList (name: value: recurse ([ name ] ++ path) value) value
        else if length path > 1 then
          { ${strings.concatStringsSep "." (reverseList path)} = value; }
        else
          { ${head path} = value; };
    in
    attrs:
    foldl recursiveUpdate { } (flatten (recurse [ ] attrs));
}
