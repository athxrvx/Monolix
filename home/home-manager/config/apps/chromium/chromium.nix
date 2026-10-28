{ ... }:

{
  programs.chromium = {
    enable = true;
    extensions = [
      { id = "jlmpjdjjbgclbocgajdjefcidcncaied"; } # daily.dev
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
      { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # SponsorBlock
      { id = "gebbhagfogifgggkldgodflihgfeippi"; } # Return YouTube Dislike
      { id = "hkgfoiooedgoejojocmhlaklaeopbecg"; } # Picture-in-Picture
      { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite
      { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # Vimium
    ];
  };
}
