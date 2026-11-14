{ primaryColor ? "green" }:
{
  colors = import ./colors/palette.nix { inherit primaryColor; };
}
