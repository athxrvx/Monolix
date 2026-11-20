(require 'posframe)
(setq f (posframe-show " *test*"
               :string "test"
               :override-parameters '((child-frame-border-width . 2) (internal-border-width . 10))))
(message "%s" (frame-parameters f))
