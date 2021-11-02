{ pkgs ? import <nixpkgs> {}
, theme ? "SpicetifyDefault"
, colorScheme ? ""
, thirdParyThemes ? {}
, thirdParyExtensions ? {}
, thirdParyCustomApps ? {}
, enabledExtensions ? []
, enabledCustomApps ? []
, spotifyLaunchFlags ? ""
, injectCss ? false
, replaceColors ? false
, overwriteAssets ? false
, disableSentry ? true
, disableUiLogging ? true
, removeRtlRule ? true
, exposeApis ? true
, disableUpgradeCheck ? true
, ...
}:

let
  inherit (pkgs.lib.lists) foldr;
  inherit (pkgs.lib.attrsets) mapAttrsToList;

  # Helper functions
  pipeConcat = foldr (a: b: a + "|" + b) "";
  lineBreakConcat = foldr (a: b: a + "\n" + b) "";
  boolToString = x: if x then "1" else "0";
  makeLnCommands = type: (mapAttrsToList (name: path: "ln -sf ${path} ./${type}/${name}"));

  # Setup spicetify
  spicetifyPkg = pkgs.callPackage ./spicetify.nix {};
  spicetify = "SPICETIFY_CONFIG=. ${spicetifyPkg}/spicetify";

  themes = pkgs.fetchFromGitHub {
    owner = "morpheusthewhite";
    repo = "spicetify-themes";
    rev = "5046217e28084f7eaf69543f1f7c1b7c276496cc";
    sha256 = "sha256-diKIBEbgru1iJ9JoU8HhRxj7ciuvc9IkSSXXqZP/iI0=";
    fetchSubmodules = true;
  };

  # Dribblish is a theme which needs a couple extra settings
  isDribblish = theme == "Dribbblish";

  extraCommands = (if isDribblish then "cp ./Themes/Dribbblish/dribbblish.js ./Extensions \n" else "")
    + (lineBreakConcat (makeLnCommands "Themes" thirdParyThemes))
    + (lineBreakConcat (makeLnCommands "Extensions" thirdParyExtensions))
    + (lineBreakConcat (makeLnCommands "CustomApps" thirdParyCustomApps));

  customAppsFixupCommands = lineBreakConcat (makeLnCommands "Apps" thirdParyCustomApps);

  injectCssOrDribblish = boolToString (isDribblish || injectCss);
  replaceColorsOrDribblish = boolToString (isDribblish || replaceColors);
  overwriteAssetsOrDribblish = boolToString (isDribblish || overwriteAssets);

  extensionString = pipeConcat ((if isDribblish then [ "dribbblish.js" ] else []) ++ enabledExtensions);
  customAppsString = pipeConcat enabledCustomApps;
in
pkgs.spotify-unwrapped.overrideAttrs (oldAttrs: rec {
  postInstall=''
    touch $out/prefs
    mkdir Themes
    mkdir Extensions
    mkdir CustomApps
    mkdir -p $out/share/spotify/Apps/zlink/css/
    touch $out/share/spotify/Apps/zlink/css/user.css

    echo $out/share/spotify/Apps/zlink/css/user.css
    ls $out/share/spotify/Apps/zlink/css/
    ls $out/share/spotify/Apps/zlink/
    ls $out/share/spotify/Apps/


    find ${themes} -maxdepth 1 -type d -exec ln -s {} Themes \;
    ${extraCommands}

    ${spicetify} config \
      spotify_path "$out/share/spotify" \
      prefs_path "$out/prefs" \
      current_theme ${theme} \
      ${if
          colorScheme != ""
        then
          ''color_scheme "${colorScheme}" \''
        else
          ''\'' }
      ${if
          extensionString != ""
        then
          ''extensions "${extensionString}" \''
        else
          ''\'' }
      ${if
          customAppsString != ""
        then
          ''custom_apps "${customAppsString}" \''
        else
          ''\'' }
      ${if
          spotifyLaunchFlags != ""
        then
          ''spotify_launch_flags "${spotifyLaunchFlags}" \''
        else
          ''\'' }
      inject_css ${injectCssOrDribblish} \
      replace_colors ${replaceColorsOrDribblish} \
      overwrite_assets ${overwriteAssetsOrDribblish} \
      disable_sentry ${boolToString disableSentry } \
      disable_ui_logging ${boolToString disableUiLogging } \
      remove_rtl_rule ${boolToString removeRtlRule } \
      expose_apis ${boolToString exposeApis } \
      disable_upgrade_check ${boolToString disableUpgradeCheck }

    ${spicetify} backup apply

    cd $out/share/spotify
    ${customAppsFixupCommands}
  '';
})
