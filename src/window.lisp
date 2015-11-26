(in-package :cl-user)
(defpackage :led.window
  (:use :cl)
  (:import-from :charms/ll
                :wattron
                :wattroff)
  (:import-from :charms
                :initialize
                :standard-window
                :disable-echoing
                :enable-raw-input
                :enable-non-blocking-mode
                :window-dimensions
                :write-char-at-point
                :move-cursor
                :refresh-window)
  (:import-from :led.character
                :ichar-val
                :ichar-attr)
  (:import-from :led.line
                :*max-line-width*
                :make-line
                :line-chars))
(in-package :led.window)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; global parameters

(defparameter *window* nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; window

(defclass window ()
  ((width :accessor window-width
          :initarg :width)
   (height :accessor window-height
           :initarg :height)
   (x :accessor window-x
      :initform 0)
   (y :accessor window-y
      :initform 0)
   (lines :accessor window-lines
          :type vector)
   (entity :accessor window-entity)))

(defclass curses-window (window) ())
(defclass debug-window (window) ())


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; initialize functions

(defun initialize-window-lines (window)
  (setq *max-line-width* (window-width window))
  (let ((lines (loop repeat (window-height window)
                     collecting (make-line) into result
                     finally (return (apply #'vector result)))))
    (setf (window-lines window) lines)))

(defun initialize-window-dimensions (window)
  (assert (typep window 'curses-window))
  (multiple-value-bind (width height) (window-dimensions (window-entity window))
    (setf (window-width window) width
          (window-height window) height)))

(defmethod initialize-instance :after ((window debug-window) &rest initargs)
  (declare (ignore initargs))
  (initialize-window-lines window)
  (setf (window-entity window) (make-array (list (window-width window) (window-height window)) :initial-element nil)))

(defmethod initialize-instance :after ((window curses-window) &rest initargs)
  (declare (ignore initargs))
  (initialize)
  (setf (window-entity window) (standard-window))
  (disable-echoing)
  (enable-raw-input :interpret-control-characters t)
  (enable-non-blocking-mode (window-entity window))
  (initialize-window-dimensions window)
  (initialize-window-lines window))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; macros

(defmacro with-curses-window (options &body body)
  (declare (ignore options))
  `(unwind-protect
        (let ((*window* (make-instance 'curses-window)))
          ,@body)
     (finalize)))


(defmacro with-debug-window (options &body body)
  (let ((width (getf options :width 50))
        (height (getf options :height 20)))
    `(let ((*window* (make-instance 'debug-window :width ,width :height ,height)))
       ,@body)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; write

(defgeneric window-write-ichar (ichar window x y))

(defmethod window-write-ichar (ichar (window curses-window) x y)
  (if (ichar-attr ichar)
      (progn (wattron (window-entity window) (ichar-attr ichar))
             (write-char-at-point (window-entity window) (ichar-val ichar) x y)
             (wattroff (window-entity window) (ichar-attr ichar)))
      (write-char-at-point (window-entity window) (ichar-val ichar) x y)))

(defmethod window-write-ichar (ichar (window debug-window) x y)
  (setf (aref (window-entity window) x y) (ichar-val ichar)))

(defun window-write-line (line window y)
  (loop for ichar across (line-chars line)
        for index from 0
        do (window-write-ichar ichar window index y)))

(defun window-write-lines (window)
  (loop for line across (window-lines window)
        for index from 0
        do (window-write-line line window index)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; update

(defgeneric update-cursor (window))

(defmethod update-cursor ((window curses-window))
  (move-cursor (window-entity window) (window-x window) (window-y window)))


(defmethod update-cursor ((window debug-window))
  (setf (aref (window-entity window) (window-x window) (window-y window)) #\*))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; refresh

(defgeneric refresh (window))

(defmethod refresh ((window curses-window))
  (refresh-window (window-entity window)))

(defmethod refresh ((window debug-window))
  (flet ((write-width-line ()
           (format t (format nil "~~~a{-~~}~~%" (+ (window-width window) 2)) :dummy)))
    (loop with entity = (window-entity window)
          for y from 0 below (array-dimension entity 1)
            initially (write-width-line)
          do (loop for x from 0 below (array-dimension entity 0)
                   for char = (aref entity x y)
                     initially (write-char #\|)
                   if char
                     do (write-char char)
                   else
                     do (write-char #\Space)
                   finally (progn (write-char #\|)
                                  (fresh-line)))
          finally (write-width-line))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; redraw

(defun redraw (&optional (window *window*))
  (window-write-lines window)
  (update-cursor window)
  (refresh window))
