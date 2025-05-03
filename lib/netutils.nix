{ lib }:

{
  /**
    Converts a prefix length to a subnet mask in dotted-decimal notation.

    # Examples

    ```nix
    prefixLengthToSubnetMask 24
    => "255.255.255.0"

    prefixLengthToSubnetMask 16
    => "255.255.0.0"

    prefixLengthToSubnetMask 8
    => "255.0.0.0"
    ```

    # Type

    ```
    prefixLengthToSubnetMask :: Int -> String
    ```
  */
  prefixLengthToSubnetMask =
    prefixLength:
    let
      # Calculate mask as integer first
      maskInt =
        (lib.foldl (acc: _: acc * 2 + 1) 0 (lib.range 1 prefixLength))
        * (lib.foldl (acc: _: acc * 2) 1 (lib.range 1 (32 - prefixLength)));

      # Split into octets
      octet1 = builtins.bitAnd (maskInt / 16777216) 255;
      octet2 = builtins.bitAnd (maskInt / 65536) 255;
      octet3 = builtins.bitAnd (maskInt / 256) 255;
      octet4 = builtins.bitAnd maskInt 255;
    in
    "${toString octet1}.${toString octet2}.${toString octet3}.${toString octet4}";
}
