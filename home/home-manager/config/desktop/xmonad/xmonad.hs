import XMonad
import XMonad.Hooks.ManageDocks (avoidStruts, docks)
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Util.SpawnOnce (spawnOnce)

main :: IO ()
main = xmonad $ docks $ def
  { modMask = mod4Mask
  , terminal = "kitty"
  , borderWidth = 2
  , focusedBorderColor = "@FOCUSED_BORDER@"
  , normalBorderColor = "@NORMAL_BORDER@"
  , workspaces = map show [1 .. 9]
  , layoutHook = avoidStruts (Tall 1 (3 / 100) (1 / 2) ||| Mirror (Tall 1 (3 / 100) (1 / 2)) ||| Full)
  , startupHook = spawnOnce "picom" >> spawnOnce "xmobar"
  }
  `additionalKeysP`
    [ ("M-<Return>", spawn "kitty")
    , ("M-S-q", kill)
    , ("M-S-r", spawn "xmonad --recompile && xmonad --restart")
    , ("M-<Print>", spawn "sh -c 'import -window root ~/Pictures/screenshot.png'")
    ]
