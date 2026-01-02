# System UI Configuration
#
# NSGlobalDomain settings for appearance, text, and behavior.
# Reference: https://nix-darwin.github.io/nix-darwin/manual/options.html

{ lib, config, ... }:
{
  system.defaults = {
    # --- NSGlobalDomain Settings ---
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleInterfaceStyleSwitchesAutomatically = false;
      AppleShowScrollBars = "Automatic";

      # Text & Typing
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticInlinePredictionEnabled = true;

      # Windows & Dialogs
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;
      NSDocumentSaveNewDocumentsToCloud = false;

      # Animations
      NSAutomaticWindowAnimationsEnabled = true;
      NSScrollAnimationEnabled = true;
      NSUseAnimatedFocusRing = true;

      # Finder Sidebar - Icon size: 1=small, 2=medium, 3=large
      NSTableViewDefaultSizeMode = 1;

      # Language & Region - Imperial system
      AppleTemperatureUnit = "Fahrenheit";
      AppleMeasurementUnits = "Inches";
      AppleMetricUnits = 0;
      AppleICUForce24HourTime = true;

      # Menu bar spacing: Spacing=gap, Padding=selection area (keep 2x ratio)
      NSStatusItemSpacing = 4;
      NSStatusItemSelectionPadding = 8;
    };

    # --- Menu Bar Clock ---
    menuExtraClock = {
      ShowDate = 1; # 0 = When space allows, 1 = Always, 2 = Never
      ShowDayOfWeek = true;
      ShowSeconds = true;
      Show24Hour = true; # Also set via AppleICUForce24HourTime
      IsAnalog = false; # false = digital, true = analog
    };

    # --- Login Window ---
    loginwindow = {
      GuestEnabled = false;
      SHOWFULLNAME = false;
    };

    # --- Screensaver & Lock ---
    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0; # 0 = immediately
    };

    # --- Screenshots ---
    screencapture = {
      # location = "/Users/${userConfig.user.name}/Screenshots";
      type = "png"; # png, jpg, gif, pdf, tiff
      disable-shadow = true;
      include-date = true;
    };

    # --- Control Center (Menu Bar) ---
    controlcenter = {
      BatteryShowPercentage = true;
      Bluetooth = true;
      Sound = true;
      Display = true;
      FocusModes = true;
      NowPlaying = true;
    };

    # --- Custom User Preferences ---
    # Settings not exposed as first-class nix-darwin options
    CustomUserPreferences = {
      "com.apple.menuextra.clock" = {
        DateFormat = "yyyy-MM-dd HH:mm:ss"; # ISO 8601 format
        FlashDateSeparators = false; # Don't blink separators
      };
    };
  };

  # --- Activation Scripts - Menu Bar Spacing ---
  # Must use -currentHost flag; requires logout/login to fully apply
  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "Applying menu bar spacing settings (compact mode)..." >&2
    spacing_applied=0

    if defaults -currentHost write -globalDomain NSStatusItemSpacing -int 4; then
      echo "Menu bar icon spacing set to 4 (compact)" >&2
      spacing_applied=1
    else
      echo "Warning: Failed to set NSStatusItemSpacing to 4 - check defaults permissions" >&2
    fi

    if defaults -currentHost write -globalDomain NSStatusItemSelectionPadding -int 8; then
      echo "Menu bar icon padding set to 8 (compact)" >&2
      spacing_applied=$((spacing_applied + 1))
    else
      echo "Warning: Failed to set NSStatusItemSelectionPadding to 8 - check defaults permissions" >&2
    fi

    if [ $spacing_applied -gt 0 ]; then
      echo "Note: Menu bar spacing changes require logout/login to fully take effect" >&2
    fi
  '';
}
