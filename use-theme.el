;;; use-theme.el -- Theme manager -*- lexical-binding: t; -*-

;; Author: Damien Merenne
;; URL: https://github.com/canatella/xwwp
;; Created: 2020-03-11
;; Keywords: convenience
;; Version: 0.1
;; Package-Requires: ((emacs "27.1") (use-package "2.4"))

;; Copyright (C) 2020 Damien Merenne <dam@cosinux.org>

;; This file is NOT part of GNU Emacs.

;; Copyright (C) 2021 Damien Merenne <dam@cosinux.org>

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:
(require 'seq)
(require 'map)
(require 'cl-macs)

(defgroup use-theme nil "Use theme customization" :group 'convenience)

(defcustom use-theme-styles nil
  "A list mapping theme to a style.

The first style will be used as a default."
  :group 'use-theme
  :type '(alist :key-type symbol :value-type symbol))

(defcustom use-theme-faces nil
  "A list mapping faces to a style.

This is usefull if you want to override some theme colors."
  :group 'use-theme
  :type '(alist :key-type symbol))

(defvar use-theme-style 'light "Current theme style.")

(defun use-theme-styles (&optional without)
  "Return the list of available style, removing WITHOUT style is provided."
  (seq-filter
   (lambda (s) (not (equal s without)))
   (map-keys use-theme-styles)))



(defun use-theme-next-style-rec (style styles)
  "Return style following STYLE in STYLES or the first if there are none."
  (seq-let
      (current &rest rest)
      styles
    (if (and style current rest)
        (if (equal style current) (car rest) (use-theme-next-style-rec style rest))
      (caar use-theme-styles))))

(defun use-theme-next-style ()
  "Return the next style in the style list."
  (use-theme-next-style-rec use-theme-style (map-keys use-theme-styles)))


(defun use-theme-sha256 (theme)
  "Return the sha256 for the current version of THEME."
  (let ((file
         (locate-file
          (concat (symbol-name theme) "-theme.el")
          (custom-theme--load-path)
          '("" "c"))))
    (with-temp-buffer (insert-file-contents file) (secure-hash 'sha256 (current-buffer)))))

;;;###autoload
(defun use-theme-switch (style)
  "Switch to theme STYLE."
  (interactive
   (list (completing-read "Style: " (use-theme-styles) nil t nil nil (use-theme-next-style))))
  (setq use-theme-style style)
  (seq-do #'disable-theme custom-enabled-themes)
  (load-theme (map-elt use-theme-styles use-theme-style)))

(defun use-theme-add (list style object)
  "Add STYLE, OBJECT to LIST."
  (append (map-delete list style) `((,style . , object))))

;;;###autoload
(defun use-theme-default ()
  "Switch to default theme."
  (interactive)
  (use-theme-switch (caar use-theme-styles)))

;;;###autoload
(defun use-theme-toggle ()
  "Toggle theme between theme styles."
  (interactive)
  (use-theme-switch (use-theme-next-style)))

(with-eval-after-load 'use-package
  (defun use-theme-plist-remove (plist keywords)
    "Remove KEYWORDS from PLIST."
    (if keywords
        (use-theme-plist-remove (map-delete plist (car keywords)) (cdr keywords))
      plist))

  (cl-defmacro
      use-theme
      (package &rest use-package-args &key disabled config name style custom-face &allow-other-keys)
    "Use package wrapper for a theme.

Specific keyword arguments:

:NAME is the theme name to load if different from package with  any `-theme*' suffix removed.

:STYLE is the style to map to the theme, for example `dark'. The
theme can then be switched using `use-theme-switch' or
`use-theme-toggle'."
    (declare (indent 1))
    (when (not disabled)
      (let* ((name
              (or name (intern (replace-regexp-in-string "-theme.*$" "" (symbol-name package)))))
             (names
              (if (listp name) name (list `(style . name))))
             (themes
              (seq-mapcat
               (lambda (styles)
                 (let* ((style (car styles))
                        (name (cdr styles))
                        (cust-styles
                         `(customize-set-variable 'use-theme-styles
                                                  (use-theme-add use-theme-styles
                                                                 (quote ,style)
                                                                 (quote ,name))))
                        (cust-faces
                         `(custom-theme-set-faces (quote, name)
                                                                 (quote ,custom-face))))
                   `(,@(seq-filter #'identity
                                   (list (when style cust-styles) (when custom-face cust-faces)))
                     (customize-set-variable 'custom-safe-themes
                                             (cons (use-theme-sha256 (quote ,name)) custom-safe-themes)))))
               names)))
        `(use-package
             ,package
           ,@(use-theme-plist-remove use-package-args '(:style :name :config))
           :config ,@themes
           ,@config
           (when (>= (length use-theme-styles) 1)
             ;; Fix loading theme with emacs daemon
             (add-hook 'server-after-make-frame-hook #'use-theme-default)
             (use-theme-switch (caar use-theme-styles))))))))


(provide 'use-theme)
;;; use-theme.el ends here
