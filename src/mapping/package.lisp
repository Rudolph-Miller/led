(in-package :cl-user)
(defpackage :led.mapping
  (:use :led.mapping.util
        :led.mapping.default)
  (:export ;; util
           :global-set-key
           :define-key))
(in-package :led.mapping)
