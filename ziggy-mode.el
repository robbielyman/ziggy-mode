;;; ziggy-mode.el --- major mode for Ziggy, a data serialization language -*- lexical-binding: t; -*-

;; Author: 2024 Robbie Lyman <rb.lymn@gmail.com>
;;
;; URL: https://github.com/robbielyman/ziggy-mode
;; Version: 0.0.1
;; Package-Requires: ((emacs "29.0"))
;;
;; This file is NOT part of Emacs.
;;
;;; License:
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
;; LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
;; WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
;;
;;; Commentary:
;; This major mode uses tree-sitter for font-lock, indentation and so on.

;;;; Code:

(require 'treesit)
(require 'reformatter)

(defgroup ziggy-mode nil
  "Tree-sitter-powered support for the Ziggy data serialization languae."
  :link '(url-link "https://ziggy-lang.io")
  :group 'languages)

(defcustom ziggy-format-on-save t
  "Format buffers before saving using ziggy fmt."
  :type 'boolean
  :safe #'booleanp
  :group 'ziggy-mode)

(defcustom ziggy-format-show-buffer t
  "Show a *ziggy-fmt* buffer after ziggy fmt completes with errors."
  :type 'boolean
  :safe #'booleanp
  :group 'ziggy-mode)

(defcustom ziggy-bin "ziggy"
  "Path to ziggy executable."
  :type 'file
  :safe #'stringp
  :group 'ziggy-mode)

;; ziggy fmt

(reformatter-define ziggy-format
  :program ziggy-bin
  :args '("fmt" "--stdin")
  :group 'ziggy-mode
  :lighter " ZiggyFmt")

;;;###autoload (autoload 'ziggy-format-buffer "current-file" nil t)
;;;###autoload (autoload 'ziggy-format-region "current-file" nil t)
;;;###autoload (autoload 'ziggy-superhtml-format-on-save-mode "current-file" nil t)

(defvar ziggy--treesit-font-lock-setting
  (treesit-font-lock-rules
   :feature 'boolean
   :language 'ziggy
   '([
      (true)
      (false)
      ] @font-lock-constant-face)

   :feature 'null
   :language 'ziggy
   '((null) @font-lock-constant-face)

   :feature 'numeric
   :language 'ziggy
   '([
      (integer)
      (float)
      ] @font-lock-constant-face)

   :feature 'keyword
   :language 'ziggy
   '((struct_field
      key: (_) @font-lock-keyword-face))

   :feature 'type
   :language 'ziggy
   '((struct
      name: (_) @font-lock-type-face))

   :feature 'function
   :language 'ziggy
   '((tag) @font-lock-function-call-face)

   :feature 'string
   :language 'ziggy
   '([
      (string)
      (line_string) :*
      ] @font-lock-string-face)

   :feature 'comment
   :language 'ziggy
   '((comment) @font-lock-comment-face)

   :feature 'escape
   :language 'ziggy
   '((escape_sequence) @font-lock-escape-face)

   :feature 'error
   :language 'ziggy
   '((ERROR) @font-lock-warning-face)

   :feature 'delimiter
   :language 'ziggy
   '("," @font-lock-delimiter-face)

   :feature 'bracket
   :language 'ziggy
   '([
      "["
      "]"
      "{"
      "}"
      "("
      ")"
      ] @font-lock-bracket-face)

   :feature 'top-comment
   :language 'ziggy
   '((top_comment) @font-lock-comment-face)
   )
  "Tree-sitter font-lock settings.")

(defvar ziggy-schema--treesit-font-lock-setting
  (treesit-font-lock-rules
   :feature 'keyword
   :language 'ziggy-schema
   '((struct_field
      key: (_) @font-lock-keyword-face))

   :feature 'function
   :language 'ziggy-schema
   '((tag_name) @font-lock-function-call-face)

   :feature 'builtin-keywords
   :language 'ziggy-schema
   '([
      "unknown"
      "any"
      "struct"
      "root"
      "enum"
      "map"
      ] @font-lock-keyword-face)

   :feature 'type
   :language 'ziggy-schema
   '((identifier) @font-lock-type-face)

   :feature 'type-builtin
   :language 'ziggy-schema
   '("?" @font-lock-type-face)

   :feature 'constant
   :language 'ziggy-schema
   '([
      "bool"
      "bytes"
      "int"
      "float"
      ] @font-lock-constant-face)

   :feature 'comment
   :language 'ziggy-schema
   '((doc_comment) @font-lock-comment-face)

   :feature 'error
   :language 'ziggy-schema
   '((ERROR) @font-lock-warning-face)

   :feature 'delimiter
   :language 'ziggy-schema
   '("," @font-lock-delimiter-face)

   :feature 'misc
   :language 'ziggy-schema
   '("|" @font-lock-misc-punctuation-face)

   :feature 'bracket
   :language 'ziggy-schema
   '([
      "["
      "]"
      "{"
      "}"
      ] @font-lock-bracket-face)
   )
  "Tree-sitter font-lock settings.")

;;;###autoload
(define-derived-mode ziggy-mode prog-mode "Ziggy"
  "A tree-sitter-powered major mode for the Ziggy data serialization language."
  :group 'ziggy-mode
  (when ziggy-format-on-save
    (ziggy-format-on-save-mode 1))
  (when (treesit-ready-p 'ziggy)
    (treesit-parser-create 'ziggy)
    (setq-local treesit-font-lock-feature-list
                '((comment error top-comment function)
                  (string keyword type)
                  (null boolean numeric escape)
                  (delimiter bracket)))
    (setq-local treesit-font-lock-settings ziggy--treesit-font-lock-setting)
    (treesit-major-mode-setup)))

;;;###autoload
(define-derived-mode ziggy-schema-mode prog-mode "Ziggy-Schema"
  "A tree-sitter-powered major mode for Ziggy schema."
  :group 'ziggy-mode
  (when ziggy-format-on-save
    (ziggy-format-on-save-mode 1))
  (when (treesit-ready-p 'ziggy-schema)
    (treesit-parser-create 'ziggy-schema)
    (setq-local treesit-font-lock-feature-list
                '((comment error function)
                  (builtin-keywords constant type-builtin)
                  (type keyword)
                  (delimiter bracket misc)))
    (setq-local treesit-font-lock-settings ziggy-schema--treesit-font-lock-setting)
    (treesit-major-mode-setup)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.\\(ziggy\\|zgy\\)\\'" . ziggy-mode))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.\\(ziggy-schema\\|zgy-schema\\)\\'" . ziggy-schema-mode))

(provide 'ziggy-mode)
(provide 'ziggy-schema-mode)
;;; ziggy-mode.el ends here
