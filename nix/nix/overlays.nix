[
  (final: prev: {
    ueberzugpp = prev.ueberzugpp.overrideAttrs (oldAttrs: {
      buildInputs =
        oldAttrs.buildInputs
        ++ prev.lib.optionals (prev.config.cudaSupport or false) [
          prev.cudaPackages.cuda_cudart
          prev.cudaPackages.cuda_nvcc
          prev.xorg.libXau
          prev.xorg.libXdmcp
        ];
    });
  })
]
