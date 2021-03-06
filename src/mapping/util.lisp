(in-package :cl-user)
(defpackage led.mapping.util
  (:use :cl
        :led.internal
        :led.buffer)
  (:export :global-set-key
           :normal-mode
           :normal-mode-and-cursor-left
           :insert-mode
           :insert-mode-and-cursor-right
           :cursor-left-most-and-insert-mode
           :cursor-right-most-and-insert-mode
           :command-line-mode
           :exit-command-line-mode))
(in-package :led.mapping.util)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; global-set-key

(defun global-set-key (mode-or-modes dsl function)
  (let ((modes (etypecase mode-or-modes
                 (cons mode-or-modes)
                 (symbol (list mode-or-modes)))))
    (dolist (mode modes)
      (register-key mode dsl function *global-key-mapping* t))
    function))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; modes

(defun normal-mode ()
  (setf (current-mode) :normal))

(defun normal-mode-and-cursor-left ()
  (normal-mode)
  (cursor-left))

(defun insert-mode ()
  (setf (current-mode) :insert))

(defun insert-mode-and-cursor-right ()
  (insert-mode)
  (cursor-right))

(defun cursor-left-most-and-insert-mode ()
  (cursor-left-most)
  (insert-mode))

(defun cursor-right-most-and-insert-mode ()
  (cursor-right-most)
  (insert-mode-and-cursor-right))

(defun command-line-mode ()
  (setf (current-mode) :command-line))

(defun exit-command-line-mode ()
  (stop-command-line-mode)
  (on-command-line "Quit"))
