local colors = require("monovim_base46").get_theme_tb "base_30"

return {
  -- Dap
  DapBreakpoint = { fg = colors.red },
  DapBreakpointCondition = { fg = colors.yellow },
  DapBreakPointRejected = { fg = colors.orange },
  DapLogPoint = { fg = colors.cyan },
  DapStopped = { fg = colors.baby_pink },
  DapStoppedLine = { bg = colors.one_bg },

  -- DapUI
  DAPUIScope = { fg = colors.cyan },
  DAPUIType = { fg = colors.dark_purple },
  DAPUIValue = { fg = colors.cyan },
  DAPUIVariable = { fg = colors.white },
  DapUIModifiedValue = { fg = colors.orange },
  DapUIDecoration = { fg = colors.cyan },
  DapUIThread = { fg = colors.green },
  DapUIStoppedThread = { fg = colors.cyan },
  DapUISource = { fg = colors.lavender },
  DapUILineNumber = { fg = colors.cyan },
  DapUIFloatBorder = { fg = colors.cyan },

  DapUIWatchesEmpty = { fg = colors.baby_pink },
  DapUIWatchesValue = { fg = colors.green },
  DapUIWatchesError = { fg = colors.baby_pink },

  DapUIBreakpointsPath = { fg = colors.cyan },
  DapUIBreakpointsInfo = { fg = colors.green },
  DapUIBreakPointsCurrentLine = { fg = colors.green, bold = true },
  DapUIBreakpointsDisabledLine = { fg = colors.grey_fg2 },

  DapUIStepOver = { fg = colors.blue },
  DapUIStepOverNC = { fg = colors.blue },
  DapUIStepInto = { fg = colors.blue },
  DapUIStepIntoNC = { fg = colors.blue },
  DapUIStepBack = { fg = colors.blue },
  DapUIStepBackNC = { fg = colors.blue },
  DapUIStepOut = { fg = colors.blue },
  DapUIStepOutNC = { fg = colors.blue },
  DapUIStop = { fg = colors.red },
  DapUIStopNC = { fg = colors.red },
  DapUIPlayPause = { fg = colors.green },
  DapUIPlayPauseNC = { fg = colors.green },
  DapUIRestart = { fg = colors.green },
  DapUIRestartNC = { fg = colors.green },
  DapUIUnavailable = { fg = colors.grey_fg },
  DapUIUnavailableNC = { fg = colors.grey_fg },

  -- DapView
  MonoimDapViewMissingData = { fg = colors.baby_pink },
  MonoimDapViewFileName = { fg = colors.vibrant_green },
  MonoimDapViewLineNumber = { fg = colors.cyan },
  MonoimDapViewSeparator = { fg = colors.light_grey },

  MonoimDapViewThread = { fg = colors.green },
  MonoimDapViewThreadStopped = { fg = colors.cyan },
  MonoimDapViewThreadError = { fg = colors.baby_pink },

  MonoimDapViewFrameCurrent = { fg = colors.orange },

  MonoimDapViewExceptionFilterEnabled = { fg = colors.green },
  MonoimDapViewExceptionFilterDisabled = { fg = colors.light_grey },

  MonoimDapViewTab = { fg = colors.light_grey, bg = colors.black2 },
  MonoimDapViewTabSelected = { fg = colors.white, bg = colors.black },

  MonoimDapViewControlNC = { fg = colors.grey_fg },
  MonoimDapViewControlPlay = { fg = colors.green },
  MonoimDapViewControlPause = { fg = colors.orange },
  MonoimDapViewControlStepInto = { fg = colors.blue },
  MonoimDapViewControlStepOut = { fg = colors.blue },
  MonoimDapViewControlStepOver = { fg = colors.blue },
  MonoimDapViewControlStepBack = { fg = colors.blue },
  MonoimDapViewControlRunLast = { fg = colors.green },
  MonoimDapViewControlTerminate = { fg = colors.red },
  MonoimDapViewControlDisconnect = { fg = colors.red },

  MonoimDapViewWatchExpr = { fg = colors.vibrant_green },
  MonoimDapViewWatchMore = { fg = colors.light_grey },
  MonoimDapViewWatchError = { fg = colors.baby_pink },
  MonoimDapViewWatchUpdated = { fg = colors.orange },

  MonoimDapViewBoolean = { link = "Boolean" },
  MonoimDapViewString = { link = "String" },
  MonoimDapViewNumber = { link = "Number" },
  MonoimDapViewFloat = { link = "Float" },
  MonoimDapViewFunction = { link = "Function" },
  MonoimDapViewConstant = { link = "Constant" },
}
