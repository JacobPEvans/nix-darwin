# System UI Configuration
#
# NSGlobalDomain settings for appearance, text, and behavior.
# Reference: https://nix-darwin.github.io/nix-darwin/manual/options.html

_: {
  system.defaults = {
    # ==========================================================================
    # NSGlobalDomain Settings
    # ==========================================================================
    NSGlobalDomain = {
      # Appearance
      # Dark mode: null = light, "Dark" = dark
      AppleInterfaceStyle = "Dark";

      # Auto-switch between light/dark based on time
      AppleInterfaceStyleSwitchesAutomatically = false;

      # Scrollbar visibility: "WhenScrolling", "Automatic", "Always"
      AppleShowScrollBars = "Automatic";

      # Text & Typing
      # Auto-capitalization
      NSAutomaticCapitalizationEnabled = false;

      # Smart dashes (-- to em dash)
      NSAutomaticDashSubstitutionEnabled = false;

      # Double-space to period
      NSAutomaticPeriodSubstitutionEnabled = false;

      # Smart quotes ("curly" instead of "straight")
      NSAutomaticQuoteSubstitutionEnabled = false;

      # Auto spell correction
      NSAutomaticSpellingCorrectionEnabled = false;

      # Inline predictive text
      NSAutomaticInlinePredictionEnabled = true;

      # Windows & Dialogs
      # Expand save panel by default
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;

      # Expand print panel by default
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;

      # Save to disk (not iCloud) by default
      NSDocumentSaveNewDocumentsToCloud = false;

      # Animations
      # Window opening/closing animations
      NSAutomaticWindowAnimationsEnabled = true;

      # Smooth scrolling
      NSScrollAnimationEnabled = true;

      # Animated focus ring
      NSUseAnimatedFocusRing = true;

      # Finder Sidebar
      # Sidebar icon size: 1 = small, 2 = medium, 3 = large
      NSTableViewDefaultSizeMode = 1;
    };

    # ==========================================================================
    # Menu Bar Clock
    # ==========================================================================
    menuExtraClock = {
      # Show date in menu bar
      ShowDate = 1; # 0 = When space allows, 1 = Always, 2 = Never

      # Show day of week
      ShowDayOfWeek = true;

      # Show seconds
      ShowSeconds = false;

      # 24-hour time (also set via AppleICUForce24HourTime)
      Show24Hour = false;

      # Analog vs digital: true = analog
      IsAnalog = false;
    };

    # ==========================================================================
    # Login Window
    # ==========================================================================
    loginwindow = {
      # Disable guest account
      GuestEnabled = false;

      # Show full name instead of username
      SHOWFULLNAME = false;
    };

    # ==========================================================================
    # Screensaver & Lock
    # ==========================================================================
    screensaver = {
      # Require password when waking from screensaver
      askForPassword = true;

      # Grace period before password required (seconds)
      # 0 = immediately
      askForPasswordDelay = 0;
    };

    # ==========================================================================
    # Screenshots
    # ==========================================================================
    screencapture = {
      # Save location: null = ~/Desktop (default)
      # location = "/Users/${userConfig.user.name}/Screenshots";

      # Image format: png, jpg, gif, pdf, tiff
      type = "png";

      # Disable drop shadow on window screenshots
      disable-shadow = true;

      # Include date in filename
      include-date = true;
    };

    # ==========================================================================
    # Control Center (Menu Bar)
    # ==========================================================================
    controlcenter = {
      # Show battery percentage
      BatteryShowPercentage = true;

      # Menu bar items visibility (true = show, false = hide)
      Bluetooth = true;
      Sound = true;
      Display = true;
      FocusModes = true;
      NowPlaying = true;
    };
  };
}
