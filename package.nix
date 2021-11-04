{ pkgs
, lib
, theme ? "Default"
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
, spicetifyPackage ? pkgs.spicetify-cli
, themesInput ? null
, ...
}:

let
  inherit (pkgs.lib.lists) foldr;
  inherit (pkgs.lib.attrsets) mapAttrsToList;

  # ----------------------------------------------------------
  themes = if themesInput == null then pkgs.fetchFromGitHub {
    owner = "morpheusthewhite";
    repo = "spicetify-themes";
    rev = "5046217e28084f7eaf69543f1f7c1b7c276496cc";
    sha256 = "sha256-diKIBEbgru1iJ9JoU8HhRxj7ciuvc9IkSSXXqZP/iI0=";
    fetchSubmodules = true;
  } else themesInput;

  spicetify = "SPICETIFY_CONFIG=. ${spicetifyPackage}/bin/spicetify-cli";
  # ----------------------------------------------------------

  # Helper functions
  pipeConcat = foldr (a: b: a + "|" + b) "";
  lineBreakConcat = foldr (a: b: a + "\n" + b) "";
  boolToString = x: if x then "1" else "0";
  makeLnCommands = type: (mapAttrsToList (name: path: "ln -sf ${path} ./${type}/${name}"));

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

  extensionString = pipeConcat ((lib.optionals isDribblish [ "dribbblish.js" ]) ++ enabledExtensions);
  customAppsString = pipeConcat enabledCustomApps;
in
pkgs.spotify-unwrapped.overrideAttrs (oldAttrs: rec {
  name = "spotify";

  postInstall=''
    touch $out/prefs
    mkdir Themes Extensions CustomApps

    find ${themes} -maxdepth 1 -type d -exec ln -s {} Themes \;
    ls -lasi Themes

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
