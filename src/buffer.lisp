(in-package :cl-user)
(defpackage led.buffer
  (:use :cl)
  (:import-from :led.util
                :make-vector-with)
  (:import-from :led.line
                :make-line
                :migrate-line-to-line)
  (:import-from :led.window
                :*window*
                :window-width
                :window-height
                :window-x
                :window-y
                :get-window-line
                :set-window-line)
  (:export :buffer
           :buffer-name
           :buffer-lines
           :migrate-buffer))
(in-package :led.buffer)

(defparameter *current-buffer* nil)

(defparameter *buffers* nil)

(defclass buffer ()
  ((name :accessor buffer-name
         :initarg :name
         :initform "No name buffer")
   (position-x :accessor buffer-position-x
               :initarg :position-x
               :initform 0)
   (position-y :accessor buffer-position-y
               :initarg :position-y
               :initform 0)
   (width :accessor buffer-width
          :initarg :width
          :initform (window-width *window*))
   (height :accessor buffer-height
           :initarg :height
           :initform (window-height *window*))
   (x :accessor buffer-x
      :initform 0)
   (y :accessor buffer-y
      :initform 0)
   (top-row :accessor buffer-top-row
            :initform 0)
   (lines :accessor buffer-lines
          :initarg :lines)))

(defmethod initialize-instance :before ((buffer buffer) &rest initargs)
  (declare (ignore buffer initargs))
  (assert *window*))
                                        
(defmethod initialize-instance :after ((buffer buffer) &rest initargs)
  (declare (ignore initargs))
  (push-buffer buffer))

(defun push-buffer (buffer)
  (push buffer *buffers*))

(defun delete-buffer (buffer)
  (setq *buffers* (remove buffer *buffers*)))

(defun pop-buffer (buffer)
  (delete-buffer buffer)
  buffer)

(defun buffer-visible-lines (buffer)
  (let ((top-row (buffer-top-row buffer)))
    (subseq (buffer-lines buffer) top-row (min (length (buffer-lines buffer)) (+ top-row (buffer-height buffer))))))

;; FIXME: Support multi buffers (like split window)
;; (defun migrate-buffers ())

(defun migrate-buffer (buffer &optional (window *window*))
  (let ((x (+ (buffer-position-x buffer) (buffer-x buffer)))
        (y (+ (buffer-position-y buffer) (buffer-y buffer)))
        (lines (buffer-visible-lines buffer)))
    (when (eq buffer *current-buffer*)
      (setf (window-x window) x)
      (setf (window-y window) y))
    (loop for line across lines
          for win-row from (buffer-position-y buffer)
          with win-col = (buffer-position-x buffer)
          for win-line = (get-window-line win-row)
          do (set-window-line (migrate-line-to-line line win-line win-col)
                              win-row))))
