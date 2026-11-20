;;; require-all-ui-modules.el --- Load supporting UI modules -*- lexical-binding: t; -*-

(straight-use-package 'svg-lib)
(straight-use-package 'mini-frame)
(straight-use-package 'neotree)

(require 'ui/base-colors)
(require 'ui/colors)
(require 'ui/faces)
(require 'ui/layout)
(require 'ui/defaults)
(require 'ui/session)
(require 'ui/bindings)
(require 'ui/help)

(require 'ui/calendar)
(require 'ui/read)
(require 'ui/dialog)
(require 'ui/sidebar)
(require 'ui/toolbar)
(require 'ui/tools)
(require 'ui/command)
(require 'ui/minibuffer)
(require 'ui/agenda)

(provide 'require-all-ui-modules)
;;; require-all-ui-modules.el ends here
