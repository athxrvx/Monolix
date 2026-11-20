;;; tty-clipboard.el --- Atomic Emacs module -*- lexical-binding: t; -*-

(defcustom lem-osc52-max-region-bytes 100000
  "Maximum kill size, in raw region bytes, that may be written to
the terminal clipboard via OSC52. Larger kills remain in the local
kill ring and emit a single message; nothing is sent to the
terminal.

The value is measured pre-encoding. Base64 inflates the wire form
by roughly 4/3 plus a small constant from the OSC52 framing
(`\\e]52;c;...\\e\\\\'). When the kill happens inside tmux, every
ESC byte in that wire form is doubled by the tmux passthrough
wrapper, which inflates again.

Terminal limits vary widely. Apple Terminal caps OSC52 sequences
near 4 KB; Blink Shell and iTerm2 are more permissive. The default
of 100000 raw bytes targets a Blink workflow with tmux. Lower the
value if a different terminal will receive the sequence."
  :type 'integer
  :group 'lambda-emacs)

(defun lem--osc52-emit (text frame)
  "Encode TEXT and send the OSC52 sequence to FRAME's terminal.

If `(string-bytes TEXT)' exceeds `lem-osc52-max-region-bytes',
the function emits a single message and returns without writing
to the terminal stream."
  (if (> (string-bytes text) lem-osc52-max-region-bytes)
      (message
       "lem-osc52: region too large for terminal clipboard (%d bytes, limit %d)"
       (string-bytes text) lem-osc52-max-region-bytes)
    (let* ((bytes (encode-coding-string text 'utf-8 t))
           (b64   (base64-encode-string bytes t))
           (raw   (concat "\e]52;c;" b64 "\e\\"))
           (seq   (if (getenv "TMUX")
                      (concat "\ePtmux;"
                              (replace-regexp-in-string "\e" "\e\e" raw)
                              "\e\\")
                    raw)))
      (send-string-to-terminal seq (frame-terminal frame)))))

(defun lem--osc52-cut-function (text)
  "Replacement for `interprogram-cut-function'.

Dispatches TEXT per frame type. Resolves the frame from the
window that displays the current buffer. On a graphic frame
(`(framep f)' is `ns', `mac', `pgtk', or `x') the function calls
`gui-select-text' so the native system clipboard receives the
write. On a tty frame the function emits an OSC52 sequence on
that frame's terminal stream. With no resolvable frame it logs a
one-line message and returns. In `--batch' (`noninteractive' is
non-nil) it is a no-op."
  (unless noninteractive
    (let* ((win   (get-buffer-window (current-buffer) t))
           (frame (window-frame win))
           (kind  (framep frame)))
      (cond
       ((memq kind '(ns mac pgtk x))
        (gui-select-text text))
       ((eq kind t)
        (lem--osc52-emit text frame))
       (t
        (message "lem-osc52: kill stayed local (no live frame)"))))))

(setq interprogram-cut-function 'lem--osc52-cut-function)

(provide 'component/tty-clipboard)
;;; lem-setup-tty-clipboard.el ends here
