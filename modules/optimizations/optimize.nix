{ ... }:
{
  nix.settings = {
    sandbox = true;
    max-jobs = "auto";
    allowed-users = [ "@wheel" ];
    trusted-users = [ "root" "@wheel" ];
};

  nix = {
    gc = { 
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;
    extraOptions = ''
#      min-free = ${toString (100 * 1024 * 1024)}
#      max-free = ${toString (1024 * 1024 * 1024)}
      fallback = true
    '';
   };

}
