{ primaryColor }:

rec {
  fg = "dedede";
  bg = "121212";
  c0 = "929292";
  c1 = "e27373";
  c2 = "94b979";
  c3 = "ffba7b";
  c4 = "97bedc";
  c5 = "e1c0fa";
  c6 = "00988e";
  c7 = "dedede";
  c8 = "bdbdbd";
  c9 = "ffa1a1";
  c10 = "bddeab";
  c11 = "ffdca0";
  c12 = "b1d8f6";
  c13 = "fbdaff";
  c14 = "1ab2a8";
  c15 = "ffffff";

  primary =
    if primaryColor == "red"
    then c1
    else if primaryColor == "green"
    then c2
    else if primaryColor == "yellow"
    then c3
    else if primaryColor == "magenta"
    then c5
    else c4;

}
