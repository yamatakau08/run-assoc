;;; run-assoc.el --- Run program or lisp function associated with a file.
;;
;; Filename: run-assoc.el
;; Description: Run program or lisp function associated with a file.
;; Authors: Emacs Wiki, pinetr2e, pft
;;
;;; Commentary
;;
;; run-assoc.el was tested with GNU Emacs 21.4 and 22.0.50.3 on debian linux.
;;
;; The idea and some portion of codes were borrowed from 'w32-browser'
;; which is only for w32 and from 'TrivialMode'.
;;
;; It is very simple to use:
;;
;; (require 'run-assoc)
;;
;; (setq associated-program-alist
;;    '(("gnochm" "\\.chm$")
;; 	("evince" "\\.pdf$")
;; 	("mplayer" "\\.mp3$")
;; 	((lambda (file)
;; 	   (let ((newfile (concat (file-name-sans-extension (file-name-nondirectory file)) ".txt")))
;; 	     (cond
;; 	      ((get-buffer newfile)
;; 	       (switch-to-buffer newfile)
;; 	       (message "Buffer with name %s exists, switching to it" newfile))
;; 	      ((file-exists-p newfile)
;; 	       (find-file newfile)
;; 	       (message "File %s exists, opening" newfile))
;; 	      (t (find-file newfile)
;; 		 (= 0 (call-process "antiword" file
;; 				    newfile t "-")))))) "\\.doc$")
;; 	("evince" "\\.ps$")
;;	("fontforge" "\\.\\(sfd\\(ir\\)?\\|ttf\\|otf\\)$")
;; 	((lambda (file)
;; 	   (browse-url (concat "file:///" (expand-file-name file)))) "\\.html?$")))
;;
;;
;;		Then, you can run the associated program in dired mode by
;;		Control-Return on a specific file or you can run the program
;;		directly by M-x run-associated-program
;;
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(defvar associated-program-alist nil
  "Associated program/function list depending on file name regexp.")

(defun run-associated-program (file-name-arg &optional wildcards) ; add optional arg to use interactive block of find-file function, actually no used
  "Run program or function associated with file-name-arg.
      If no application is associated with file, then `find-file'."
  ;; modified to use same interactive block of find-file function.
  ;; because C-x C-f assigned run-associated-program original (interactive "ffile:") can't handle directory correctly inside buffer of file.
  (interactive
   (find-file-read-args "Find file: "
                        (confirm-nonexistent-file-or-buffer)))
  (let ((items associated-program-alist)
	item
	program
	regexp
	file-name
	result)
    (setq file-name (expand-file-name file-name-arg))
    (while (and (not result) items)
      (setq item (car items))
      (setq program (nth 0 item))
      (setq regexp (nth 1 item))
      (if (string-match regexp file-name)
	  (cond ((stringp program)
		 (setq result (start-process program nil program file-name)))
		((functionp program)
;		 (funcall program
;			  (replace-regexp-in-string "/" "\\\\" file-name) ; modified to change windows path to internal one
;			  )
		 (funcall program file-name)
		 ;; This implementation assumes everything went well,
		 ;; or that the called function handled an error by
		 ;; itself:
		 (setq result t))))
      (setq items (cdr items)))
    ;; fail to run
    (unless result
      (find-file file-name) ; modified to use "file-name" as arg, original arg is "file" is nill with calling this func directry means without interactive call
      )))

(defun dired-run-associated-program ()
  "Run program or function associated with current line's file.
      If file is a directory, then `dired-find-file' instead.  If no
      application is associated with file, then `find-file'."
  (interactive)
  (run-associated-program
   ;; modified to use 'dired-get-file-for-visit, original is 'dired-get-filename.
   ;; because dired-get-file-name has error when select '.' or '..' in dired mode
   (dired-get-file-for-visit)
   ))

(eval-after-load "dired"
  '(progn
     (define-key dired-mode-map [C-return] 'dired-run-associated-program)
     (define-key dired-mode-map [menu-bar immediate dired-run-associated-program]
       '("Open Associated Application" . dired-run-associated-program))))

(provide 'run-assoc)
