{ ... }:
{
  # Run only the background daemon; Monolix provides the device controls.
  services.kdeconnect = {
    enable = true;
    indicator = false;
  };

  # Keep KDE Connect's separate desktop window out of the Monolix launcher.
  xdg.desktopEntries."org.kde.kdeconnect.app" = {
    name = "KDE Connect";
    exec = "kdeconnect-app";
    type = "Application";
    categories = [ "Network" "Utility" ];
    noDisplay = true;
  };

  # KDE Connect ships standalone helper windows which are not used by this
  # setup; device management lives in the Monolix Cross Device page.
  xdg.desktopEntries."org.kde.kdeconnect.sms" = {
    name = "KDE Connect SMS";
    exec = "kdeconnect-sms";
    type = "Application";
    categories = [ "Network" "Utility" ];
    noDisplay = true;
  };

  xdg.desktopEntries."org.kde.kdeconnect.nonplasma" = {
    name = "KDE Connect Indicator";
    exec = "kdeconnect-indicator";
    type = "Application";
    categories = [ "Network" "Utility" ];
    noDisplay = true;
  };
}
