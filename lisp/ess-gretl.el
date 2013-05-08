;; ess-gretl.el --- ESS gretl mode and inferior interaction
;;
;; Copyright (C) 2012 Allin Cottrell
;; Copyright (C) 2012 Ahmadou DICKO.
;; Copyright (C) 2013 ESS core team.
;;
;; Filename: ess-gretl.el
;; Author: Ahmadou DICKO, Spinu Vitalie and Allin Cottrell (based on ess-julia.el and gretl.el)
;; Maintainer: Ahmadou DICKO
;; Created: 01-10-2012 (ESS 12.09)
;; Keywords: ESS, gretl, econometrics
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;

;; This file is *NOT* part of GNU Emacs.
;; This file is *NOT YET* part of ESS
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, any later version.
;;
;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;; details.
;;
;; You should have received a copy of the GNU General Public License along with
;; this program; see the file COPYING.  If not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
;; USA.
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;  start the inferior with M-x gretl.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(require 'compile); for compilation-* below


;;; Code:
(defvar gretl-mode-hook nil)
(add-to-list 'auto-mode-alist '("\\.inp$" . gretl-mode))


(defvar gretl-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_ "w" table)   ; underscores in words
    (modify-syntax-entry ?@ "w" table)
    (modify-syntax-entry ?# "<" table)   ; #  single-line comment start
    (modify-syntax-entry ?\n ">" table)  ; \n single-line comment end
    (modify-syntax-entry ?\{ "(} " table)
    (modify-syntax-entry ?\} "){ " table)
    (modify-syntax-entry ?\[ "(] " table)
    (modify-syntax-entry ?\] ")[ " table)
    (modify-syntax-entry ?\( "() " table)
    (modify-syntax-entry ?\) ")( " table)
    (modify-syntax-entry ?\r " "  table)
    (modify-syntax-entry ?+ "."   table)
    (modify-syntax-entry ?- "."   table)
    (modify-syntax-entry ?= "."   table)
    (modify-syntax-entry ?* "."   table)
    (modify-syntax-entry ?/ "."   table)
    (modify-syntax-entry ?> "."   table)
    (modify-syntax-entry ?< "."   table)
    (modify-syntax-entry ?& "."   table)
    (modify-syntax-entry ?| "."   table)
    (modify-syntax-entry ?! "."   table)
    (modify-syntax-entry ?\\ "\\" table)
    (modify-syntax-entry ?\' "."  table)
    (modify-syntax-entry ?\` "w"  table)
    (modify-syntax-entry ?\" "\"" table)
    (modify-syntax-entry ?. "w"   table)
    (modify-syntax-entry ?_ "w"   table)
    (modify-syntax-entry ?\% "."  table)
    (modify-syntax-entry ?\# "<"  table)
    (modify-syntax-entry ?\n ">"  table)
    table)
  "Syntax table for gretl-mode")

;; syntax table that holds within strings
(defvar gretl-mode-string-syntax-table
  (let ((table (make-syntax-table)))
    table)
  "Syntax table for gretl-mode")

(defcustom gretl-continuation-offset 4
  "*Extra indentation applied to Gretl continuation lines."
  :type 'integer
  :group 'ess-gretl)

(defvar gretl-continuation-regexp
  "[^#%\n]*\\(\\\\\\|\\.\\.\\.\\)\\s-*\\(\\s<.*\\)?$")

(defcustom gretl-continuation-string "\\"
  "*Character string used for Gretl continuation lines.  Normally \\."
  :type 'string
  :group 'ess-gretl)

;; (defconst gretl-string-regex
;;   "\"[^\"]*?\\(\\(\\\\\\\\\\)*\\\\\"[^\"]*?\\)*\"")

(defconst gretl-function-header-regexp
  (concat "^\\s-*\\<\\(function\\)\\>"
	  "\\([^=;\n]*=[ \t]*\\|[ \t]*\\)\\(\\w+\\)\\>")
  "Regexp to match a Gretl function header.
The string `function' and its name are given by the first and third
parenthetical grouping.")

;; (defconst ess-function-call-regexp
;;   "\\s\"?\\(\\(\\sw\\|\\s_\\)+\\(<-\\)?\\)\\s\"?*\\s-*("
;;   "Regexp for function names")

(defvar gretl-command-words
 '("add" "adf" "anova" "append" "ar" "ar1" "arbond" "arch"
   "arima" "biprobit" "break" "boxplot" "chow" "clear" "coeffsum" "coint"
   "coint2" "corr" "corrgm" "cusum" "data" "dataset" "delete" "diff"
   "difftest" "discrete" "dpanel" "dummify" "duration" "elif" "else" "end"
   "endif" "endloop" "eqnprint" "equation" "estimate" "fcast" "foreign" "fractint"
   "freq" "function" "funcerr" "garch" "genr" "gmm" "gnuplot" "graphpg"
   "hausman" "heckit" "help" "hsk" "hurst" "if" "include" "info"
   "intreg" "kalman" "kpss" "labels" "lad" "lags" "ldiff" "leverage"
   "levinlin" "logistic" "logit" "logs" "loop" "mahal" "makepkg" "meantest"
   "mle" "modeltab" "modprint" "modtest" "mpols" "negbin" "nls" "normtest"
   "nulldata" "ols" "omit" "open" "orthdev" "outfile" "panel" "pca"
   "pergm" "textplot" "poisson" "print" "printf" "probit" "pvalue" "quantreg"
   "qlrtest" "qqplot" "quit" "rename" "reset" "restrict" "rmplot" "run"
   "runs" "scatters" "sdiff" "set" "setinfo" "setobs" "setmiss" "shell"
   "smpl" "spearman" "sprintf" "square" "sscanf" "store" "summary" "system"
   "tabprint" "tobit" "tsls" "var" "varlist" "vartest" "vecm" "vif"
   "wls" "xcorrgm" "xtab" "debug" "return" "catch" "for" "foreach"
   "funcerr" "return" "while" "elif" "const" "3sls" "liml" "fiml"
   "sur" "params" "deriv" "orthog" "weights" "series" "scalar" "genr")
  "Commands in Gretl (these names are also reserved).")

(defvar gretl-genr-functions
 '("abs" "sin" "cos" "tan" "asin" "acos" "atan" "sinh"
   "cosh" "tanh" "asinh" "acosh" "atanh" "log" "ln" "log10"
   "log2" "exp" "sqrt" "diff" "ldiff" "sdiff" "lags" "int"
   "round" "ceil" "floor" "sort" "dsort" "sortby" "ranking" "orthdev"
   "nobs" "firstobs" "lastobs" "uniform" "normal" "cum" "missing" "ok"
   "misszero" "lrvar" "quantile" "median" "gini" "zeromiss" "sum" "mean"
   "min" "max" "sd" "var" "sst" "cnorm" "dnorm" "qnorm"
   "gammafun" "lngamma" "digamma" "resample" "pnobs" "pmin" "pmax" "pmean"
   "psd" "hpfilt" "bkfilt" "bwfilt" "fracdiff" "boxcox" "cov" "corr"
   "movavg" "I" "zeros" "ones" "seq" "replace" "muniform" "mnormal"
   "sumc" "sumr" "meanc" "meanr" "sdc" "minc" "maxc" "minr"
   "maxr" "iminc" "imaxc" "iminr" "imaxr" "fft" "ffti" "cmult"
   "cdiv" "mcov" "mcorr" "mxtab" "cdemean" "cholesky" "psdroot" "inv"
   "invpd" "ginv" "diag" "transp" "vec" "vech" "unvech" "upper"
   "lower" "rows" "cols" "det" "ldet" "tr" "onenorm" "infnorm"
   "rcond" "rank" "qform" "mlag" "qrdecomp" "eigensym" "eigengen" "nullspace"
   "princomp" "mexp" "fdjac" "BFGSmax" "obsnum" "isseries" "isscalar" "islist"
   "isstring" "isnull" "nelem" "pdf" "cdf" "invcdf" "pvalue" "critical"
   "randgen" "urcpval" "values" "mshape" "svd" "mols" "mpols" "mrls"
   "mread" "mwrite" "selifc" "selifr" "polroots" "dummify" "wmean" "wvar"
   "wsd" "xpx" "filter" "kfilter" "ksmooth" "ksimul" "trimr" "getenv"
   "argname" "obslabel" "readfile" "grab" "strstr" "strncmp" "strlen" "sscanf"
   "varname" "varnum" "tolower" "colnames" "rownames" "ljungbox" "msortby" "lincomb"
   "imhof" "toepsolv" "diagcat" "xmin" "xmax" "corrgm" "mcovg" "fcstats"
   "bessel" "fraclag" "mreverse" "deseas" "pergm" "irr" "npv" "logistic"
   "weekday" "kdensity" "monthlen" "epochday" "setnote" "invmills" "polyfit" "chowlin"
   "varsimul" "strsplit" "inlist" "errmsg" "isconst" "irf" "inbundle")
  "Builtin functions for Gretl's genr command.")


(defvar gretl-option-flags
 '("addstats" "all" "anova" "append"
   "arch" "arma-init" "asymptotic" "autocorr" "auto"
   "autocorr" "auxiliary" "balanced" "bartlett"
   "between" "bootstrap" "both" "breusch-pagan"
   "byobs" "by" "c" "close"
   "coded" "cols" "column" "comfac"
   "complete" "conditional" "contiguous" "continue"
   "continuous" "control" "covariance" "cross"
   "cross-section" "crt" "csv" "ct"
   "ctt" "cubes-only" "dat" "database"
   "dataset" "db" "degrees" "dhansen"
   "difference" "diffuse" "discrete" "dpdstyle"
   "drop-empty" "drop-first" "drop-last" "dummy"
   "dynamic" "equal" "exit" "exponential"
   "fcp" "fixed-effects" "from-file" "full"
   "func" "gamma" "geomean" "gls"
   "gmm" "gnu-R" "gnu-octave" "gph"
   "gzipped" "hausman-reg" "hessian" "hilu"
   "impulse-responses" "input" "inst" "integrate"
   "intervals" "inverse-fit" "iterate" "jackknife"
   "jbera" "jitter" "jmulti" "kendall"
   "lags" "lagselect" "lbfgs" "lillie"
   "liml" "linear-fit" "list" "loess-fit"
   "log" "loglogistic" "lognormal" "logs"
   "matrix" "matrix-diff" "medians" "ml"
   "model1" "multi" "multinomial" "nc"
   "next" "no-corc" "no-dates" "no-df-corr"
   "no-gradient-check" "no-header" "no-missing" "no-scaling"
   "no-stats" "normal" "normality" "notches"
   "numerical" "odbc" "omit-obs" "one-scale"
   "opg" "orthdev" "other" "out-of-sample"
   "output" "overwrite" "p-values" "panel"
   "panel-vars" "plot" "pooled" "preserve"
   "print-final" "progress-bar" "progressive" "pwe"
   "quadratic-fit" "quiet" "quit" "radians"
   "random" "random-effects" "rank-sum" "raw"
   "rc" "replace" "restrict" "restructure"
   "reverse" "robust" "rolling" "row"
   "rtf" "save" "save-all" "save-ehat"
   "save-xbeta" "scalars" "seasonals" "send-data"
   "sign" "signed-rank" "silent" "simple"
   "simple-print" "single-yaxis" "skip-df" "spearman"
   "special-time-series" "squares" "squares-only" "stacked-cross-section"
   "stacked-time-series" "static" "stdresid" "suppress-fitted"
   "swilk" "system" "t-ratios" "tall"
   "test-down" "tex" "time-dummies" "time-series"
   "to-file" "to_file" "traditional" "trend"
   "two-step" "unequal-vars" "uniform" "unit-weights"
   "variance-decomp" "vcv" "verbose" "wald"
   "weibull" "weights" "white" "white-nocross"
   "with-impulses" "with-lines" "write" "www"
   "x-12-arima" "y-diff-only" "z-scores" "zeros")
  "Gretl option flags.")

(defvar gretl-internal-vars
 '("Fstat" "T" "ahat" "aic" "bic" "chisq" "coeff_ci"
   "coeff" "compan" "datatype" "df" "dwpval" "ec" "ehat"
   "error" "ess" "fcast" "fcerr" "gmmcrit" "hausman" "hqc"
   "h" "jalpha" "jbeta" "jvbeta" "kalman_llt" "kalman_lnl" "kalman_s2"
   "kalman_t" "kalman_uhat" "llt" "lnl" "mnlprobs" "ncoeff" "nobs"
   "nscan" "nvars" "obs" "pd" "pvalue" "rho" "rlnl"
   "rsq" "s00" "s01" "s11" "sample" "sargan" "sigma"
   "stderr" "stopwatch" "sysA" "sysB" "sysGamma" "t1" "t2"
   "test" "trsq" "uhat" "unit" "vcv" "version" "vma"
   "windows" "xlist" "xtxinv" "yhat" )
  "Model- and dataset-related variables.")

(defconst gretl-block-start-keywords
  (list "loop" "foreign" "function" "gmm" "if" "system" "mle" "nls" "restrict"))

(defconst gretl-block-other-keywords
  (list "else" "elif"))

(defconst gretl-block-end-keywords
  (list "end" "endif" "endloop"))

(defvar gretl-keywords
  (append gretl-block-start-keywords
	  gretl-block-other-keywords
	  gretl-block-end-keywords
	  '("break"))
  "Reserved words in Gretl.")


(defun gretl-at-keyword (kw-list)
  ; not a keyword if used as a field name, X.word, or quoted, :word
  (and (or (= (point) 1)
	   (and (not (equal (char-before (point)) ?.))
		(not (equal (char-before (point)) ?:))))
       (not (ess-inside-string-or-comment-p (point)))
       (not (ess-inside-brackets-p (point)))
       (member (current-word) kw-list)))


(defconst gretl-font-lock-defaults
  (list
   ;; Fontify all builtin keywords.
   (cons (concat "\\<\\("
		 (mapconcat 'identity gretl-keywords "\\|")
		 "\\)\\>")
	 'font-lock-keyword-face)
   ;; Fontify all option flags.
   (cons (concat "[ \t]--\\("
		 (mapconcat 'identity gretl-option-flags "\\|")
		 "\\)")
	 'font-lock-constant-face)
   ;; Fontify all command words.
   (cons (concat "\\<\\("
		 (mapconcat 'identity gretl-command-words "\\|")
		 "\\)\\>")
	 'font-lock-builtin-face)
   ;; Fontify all builtin operators.
   (cons "\\(&\\||\\|<=\\|>=\\|==\\|<\\|>\\|!=\\|!\\)"
	 (if (boundp 'font-lock-builtin-face)
	     'font-lock-builtin-face
	   'font-lock-preprocessor-face))
   ;; Fontify all internal variables.
   (cons (concat "\\$\\("
		 (mapconcat 'identity gretl-internal-vars "\\|")
		 "\\)\\>")
	 'font-lock-variable-name-face)

   ;; Fontify all genr functions.
   (cons (concat "\\<\\("
		 (mapconcat 'identity gretl-genr-functions "\\|")
		 "\\)\\>")
	 'font-lock-variable-name-face)
   ;; Fontify all function declarations.
   (list gretl-function-header-regexp
	 '(1 font-lock-keyword-face)
	 '(3 font-lock-function-name-face nil t)))
  "Additional Gretl expressions to highlight.")


(defvar gretl-block-begin-regexp
  (concat "\\<\\("
	  (mapconcat 'identity gretl-block-start-keywords "\\|")
	  "\\)\\>"))

(defvar gretl-block-else-regexp
  (concat "\\<\\("
	  (mapconcat 'identity gretl-block-other-keywords "\\|")
	  "\\)\\>"))

(defvar gretl-block-end-regexp
  (concat "\\<\\("
	  (mapconcat 'identity gretl-block-end-keywords "\\|")
	  "\\)\\>"))

(defvar gretl-block-begin-or-end-regexp
  (concat gretl-block-begin-regexp "\\|" gretl-block-end-regexp))


(defvar gretl-block-else-or-end-regexp
  (concat gretl-block-else-regexp "\\|" gretl-block-end-regexp))


(defvar gretl-block-match-alist
  '(("loop" . ("endloop"))
    ("if" . ("else" "elif" "endif"))
    ("nls" . ("end"))
    ("mle" . ("end"))
    ("gmm" . ("end"))
    ("foreign" . ("end"))
    ("restrict" . ("end"))
    ("kalman" . ("end"))
    ("system" . ("end")))
  "Alist with Gretl's matching block keywords.
Has Gretl's begin keywords as keys and a list of the matching else or
end keywords as associated values.")



; get the position of the last open block
(defun gretl-last-open-block-pos (min)
  (let ((count 0))
    (while (not (or (> count 0) (<= (point) min)))
      (backward-word 1)
      (setq count
	    (cond ((gretl-at-keyword gretl-block-start-keywords)
		   (+ count 1))
		  ((and (zerop (string-match "\\(?:e\\(?:l\\(?:if\\|se\\)\\|nd\\(?:if\\|loop\\)?\\)\\)" (current-word)))
			(not (ess-inside-comment-p)) (not (ess-inside-brackets-p)))
		   (- count 1))
		  (t count))))
    (if (> count 0)
	(point)
      nil)))


(defun gretl-last-open-block (min)
  (let ((pos (gretl-last-open-block-pos min)))
    (and pos
	 (progn
	   (goto-char pos)
	   (+ gretl-basic-offset (current-indentation))))))


; return indent implied by a special form opening on the previous line, if any
(defun gretl-form-indent ()
  (forward-line -1)
  (end-of-line)
  (backward-sexp)
  (if (gretl-at-keyword gretl-block-other-keywords)
      (+ gretl-basic-offset (current-indentation))
    (if (char-equal (char-after (point)) ?\()
        (progn
          (backward-word 1)
          (let ((cur (current-indentation)))
            (if (gretl-at-keyword gretl-block-start-keywords)
                (+ gretl-basic-offset cur)
              nil)))
      nil)))


(defmacro error2nil (body) `(condition-case nil ,body (error nil)))

(defun gretl-indent-line ()
  "Indent current line of gretl code"
  (interactive)
					;  (save-excursion
    (end-of-line)
    (indent-line-to
     (or (and (ess-inside-string-p (point-at-bol)) 0)
	 (save-excursion (error2nil (gretl-form-indent)))
         (save-excursion (error2nil (gretl-paren-indent)))
         (save-excursion
           (let ((endtok (progn
                           (beginning-of-line)
                           (forward-to-indentation 0)
                           (gretl-at-keyword gretl-block-end-keywords))))
             (error2nil (+ (gretl-last-open-block (point-min))
                           (if endtok (- gretl-basic-offset) 0)))))
	 ;; previous line ends in =
	 (save-excursion
	   (if (and (not (equal (point-min) (line-beginning-position)))
		    (progn
		      (forward-line -1)
		      (end-of-line) (backward-char 1)
		      (equal (char-after (point)) ?=)))
	       (+ gretl-basic-offset (current-indentation))
	     nil))
	 ;; take same indentation as previous line
	 (save-excursion (forward-line -1)
			 (current-indentation))
         0))
    (when (gretl-at-keyword gretl-block-end-keywords)
      (forward-word 1)))



(defvar gretl-editing-alist
  '((paragraph-start		  . (concat "\\s-*$\\|" page-delimiter))
    (paragraph-separate		  . (concat "\\s-*$\\|" page-delimiter))
    (paragraph-ignore-fill-prefix . t)
    (require-final-newline	  . t)
    (comment-start		  . "# ")
    (comment-add                  . 1)
    (comment-start-skip		  . "\\s<+\\s-*")
    (comment-column		  . 40)
    ;;(comment-indent-function	  . 'S-comment-indent)
    ;;(ess-comment-indent	  . 'S-comment-indent)
    ;;(ess-indent-line		  . 'S-indent-line)
    (ess-calculate-indent	  . 'ess-calculate-indent)
    (ess-indent-line-function	  . 'gretl-indent-line)
    (parse-sexp-ignore-comments	  . t)
    (ess-style		  	  . ess-default-style) ;; ignored
    (ess-local-process-name	  . nil)
    ;;(ess-keep-dump-files	    . 'ask)
    (ess-mode-syntax-table	  . gretl-syntax-table)
  ;;  (add-log-current-defun-header-regexp . "^.*function[ \t]*\\([^ \t(]*\\)[ \t]*(")
    (font-lock-defaults		  . '(gretl-font-lock-defaults))
    )
  "General options for R source files.")

(autoload 'inferior-ess "ess-inf" "Run an ESS process.")
(autoload 'ess-mode     "ess-mode" "Edit an ESS process.")



;; (defun gretl-send-string-function (process string visibly)
;;   (let ((gretl-process (get-process "gretlcli")))
;;     (process-send-string process (format inferior-ess-load-command file)))


;; (defun gretl-send-string-function (process string visibly)
;;   (let ((file (concat temporary-file-directory "gretl_eval_region.inp")))
;;     (with-temp-file file
;;       (insert string))
;;     (process-send-string process (format inferior-ess-load-command file))))

;; (defun gretl-get-help-topics-function (name)
;;   (let ((com "help"))
;;     (ess-get-words-from-vector com)))
    ;; (ess-command com)))

;; (defvar gretl-help-command " help %s")

;; (defvar ess-gretl-error-regexp-alist '(gretl-in gretl-at)
;;   "List of symbols which are looked up in `compilation-error-regexp-alist-alist'.")

;; (add-to-list 'compilation-error-regexp-alist-alist
;;              '(gretl-in  "^\\s-*in [^ \t\n]* \\(at \\(.*\\):\\([0-9]+\\)\\)" 2 3 nil 2 1))
;; (add-to-list 'compilation-error-regexp-alist-alist
;;              '(gretl-at "^\\s-*\\(at \\(.*\\):\\([0-9]+\\)\\)"  2 3 nil 2 1))



(defvar gretl-customize-alist
  '((comint-use-prompt-regexp		. t)
    (inferior-ess-primary-prompt	. "\\? ")
    (inferior-ess-secondary-prompt	. "\\ ")
    (inferior-ess-prompt		. "\\? ")
    (ess-local-customize-alist		. 'gretl-customize-alist)
    (inferior-ess-program		. "gretlcli")
    (inferior-ess-font-lock-defaults	. gretl-font-lock-defaults)
    ;; (ess-get-help-topics-function	. 'gretl-get-help-topics-function)
    (inferior-ess-load-command		. "open \"%s\"\n")
    ;; (ess-dump-error-re			. "in \\w* at \\(.*\\):[0-9]+")
    ;; (ess-error-regexp			. "\\(^\\s-*at\\s-*\\(?3:.*\\):\\(?2:[0-9]+\\)\\)")
    ;; (ess-error-regexp-alist		. ess-gretl-error-regexp-alist)
    (ess-send-string-function		. 'gretl-send-string-function)
    ;; (inferior-ess-objects-command	. inferior-R-objects-command)
    ;; (inferior-ess-search-list-command	. "search()\n")
    ;; inferior-ess-help-command		. gretl-help-command)
    (inferior-ess-help-command		. "help %s\n")
    (ess-language			. "gretl")
    (ess-dialect			. "gretl")
    (ess-suffix				. "inp")
    (ess-dump-filename-template		. (ess-replace-regexp-in-string
					   "S$" ess-suffix ; in the one from custom:
					   ess-dump-filename-template-proto))
    (ess-mode-syntax-table		. gretl-syntax-table)
    (ess-mode-editing-alist	        . gretl-editing-alist)
    (ess-change-sp-regexp		. nil );ess-R-change-sp-regexp)
    (ess-help-sec-regex			. ess-help-R-sec-regex)
    (ess-help-sec-keys-alist		. ess-help-R-sec-keys-alist)
    (ess-loop-timeout			. ess-S-loop-timeout);fixme: dialect spec.
    (ess-cmd-delay			. ess-R-cmd-delay)
    (ess-function-pattern		. ess-R-function-pattern)
    (ess-object-name-db-file		. "ess-r-namedb.el" )
    (ess-imenu-mode-function		. 'ess-imenu-R)
    (ess-smart-operators		. ess-R-smart-operators)
    (inferior-ess-help-filetype        . nil)
    (inferior-ess-exit-command		. "exit\n")
    ;;harmful for shell-mode's C-a: -- but "necessary" for ESS-help?
    (inferior-ess-start-file		. nil) ;; "~/.ess-R"
    (inferior-ess-start-args		. "")
    (inferior-ess-language-start	. nil)
    (ess-STERM		. "iESS")
    (ess-editor	. R-editor)
    (ess-pager		. R-pager)
    )
  "Variables to customize for Gretl -- set up later than emacs initialization.")

;; (defcustom inferior-gretl-program-name "gretlcli"
;;   "*The program to use for running gretl scripts."
;;   :type 'string
;;   :group 'ess-gretl)

;; (defvar ess-gretl-versions '("gretcli")
;;   "List of partial strings for versions of Julia to access within ESS.
;; Each string specifies the start of a filename.  If a filename
;; beginning with one of these strings is found on `exec-path', a M-x
;; command for that version of Julia is made available.  ")

(defcustom inferior-gretl-args ""
  "String of arguments (see 'R --help') used when starting R.
These arguments are currently not passed to other versions of R that have
been created using the variable `ess-r-versions'."
  :group 'ess-gretl
  :type 'string)


;;;###autoload
(defun gretl-mode  (&optional proc-name)
  "Major mode for editing R source.  See `ess-mode' for more help."
  (interactive "P")
  ;; (setq ess-customize-alist gretl-customize-alist)
  ;;(setq imenu-generic-expression R-imenu-generic-expression)
  (ess-mode gretl-customize-alist proc-name)
  ;; for emacs < 24
  ;; (add-hook 'comint-dynamic-complete-functions 'ess-complete-object-name nil 'local)
  ;; for emacs >= 24
  ;; (remove-hook 'completion-at-point-functions 'ess-filename-completion 'local) ;; should be first
  ;; (add-hook 'completion-at-point-functions 'ess-object-completion nil 'local)
  ;; (add-hook 'completion-at-point-functions 'ess-filename-completion nil 'local)
  (if (fboundp 'ess-add-toolbar) (ess-add-toolbar))
  (set (make-local-variable 'end-of-defun-function) 'ess-end-of-function)
  ;; (local-set-key  "\t" 'gretl-indent-line) ;; temp workaround
  ;; (set (make-local-variable 'indent-line-function) 'gretl-indent-line)
  (set (make-local-variable 'gretl-basic-offset) 4)
 ;; (ess-imenu-gretl)
  (run-hooks 'gretl-mode-hook))


(defvar ess-gretl-post-run-hook nil
  "Functions run in process buffer after the initialization of
  Gretl process.")


;; (defun gretl (&optional start-args)
;;   "Call Gretl."
;;   (interactive "P")
;;   (setq ess-customize-alist gretl-customize-alist)
;;   (ess-write-to-dribble-buffer
;;    (format "(Gretl): ess-dialect=%s , buf=%s \n"
;;            ess-dialect
;;            (current-buffer)))
;;   (let ((gretl-start-args 
;;          (concat inferior-gretl-args " "
;;                  (when start-args (read-string "Starting Args ")))))
;;     (inferior-ess gretl-start-args)

;;       ;;(ess-tb-start)
;;       ;;   (set (make-local-variable 'font-lock-syntactic-keywords)
;;       ;;        (list
;;       ;; 	(list gretl-char-regex 2
;;       ;; 	      gretl-mode-char-syntax-table)
;;       ;; ;        (list gretl-string-regex 0
;;       ;; ;              gretl-mode-string-syntax-table)
;;       ;; ))
;;       (set (make-local-variable 'indent-line-function) 'gretl-indent-line)
;;       (set (make-local-variable 'gretl-basic-offset) 4)
;;       (setq indent-tabs-mode nil)
;;       ;; (if inferior-ess-language-start
;;       ;; 	(ess-eval-linewise inferior-ess-language-start
;;       ;; 			   nil nil nil 'wait-prompt)))
;;       (with-ess-process-buffer nil
;;         (run-mode-hooks 'ess-gretl-post-run-hook))
;;       ))





;;;###autoload
(defun gretl (&optional start-args)
  "Call 'gretl',
Optional prefix (C-u) allows to set command line arguments, such as
--vsize.  This should be OS agnostic.
If you have certain command line arguments that should always be passed
to R, put them in the variable `inferior-gretl-args'."
  (interactive "P")
  ;; get settings, notably inferior-R-program-name :
  ;; (if (null inferior-gretl-program-name)
  ;;     (error "'inferior-gretl-program-name' does not point to 'gretl-release-basic' executable")
    (setq ess-customize-alist gretl-customize-alist)
    (ess-write-to-dribble-buffer   ;; for debugging only
     (format
      "\n(Gretl): ess-dialect=%s, buf=%s"
      ess-dialect (current-buffer) start-args current-prefix-arg))
    (let* ((r-start-args
	    (concat inferior-gretl-args " " ; add space just in case
		    (if start-args
			(read-string
			 (concat "Starting Args [other than `"
				 inferior-gretl-args
				 "'] ? "))
		      nil))))
      (inferior-ess r-start-args) ;; -> .. (ess-multi ...) -> .. (inferior-ess-mode) ..
;;      (ess-tb-start)
      ;;   (set (make-local-variable 'font-lock-syntactic-keywords)
      ;;        (list
      ;; 	(list gretl-char-regex 2
      ;; 	      gretl-mode-char-syntax-table)
      ;; ;        (list gretl-string-regex 0
      ;; ;              gretl-mode-string-syntax-table)
      ;; ))
      (set (make-local-variable 'indent-line-function) 'gretl-indent-line)
      (set (make-local-variable 'gretl-basic-offset) 4)
      (setq indent-tabs-mode nil)
      ;; (if inferior-ess-language-start
      ;; 	(ess-eval-linewise inferior-ess-language-start
      ;; 			   nil nil nil 'wait-prompt)))
      (with-ess-process-buffer nil
        (run-mode-hooks 'ess-gretl-post-run-hook))
      ))


;;;; IMENU

;; (defvar gretl-imenu-generic-expression
;;   '(("Function (_)" "^\\s-*function\\s-+\\(_[^ \t\n]*\\)" 1)
;;     ("Function" "^\\s-*function\\s-+\\([^_][^ \t\n]*\\)" 1)
;;     ("Const" "^\\s-*const \\([^ \t\n]*\\)" 1)
;;     ("Type"  "^\\s-*\\w*type\\w* \\([^ \t\n]*\\)" 1)
;;     ("Load"      " *\\(load\\)(\\([^ \t\n)]*\\)" 2)
;;     ;; ("Classes" "^.*setClass(\\(.*\\)," 1)
;;     ;; ("Coercions" "^.*setAs(\\([^,]+,[^,]*\\)," 1) ; show from and to
;;     ;; ("Generics" "^.*setGeneric(\\([^,]*\\)," 1)
;;     ;; ("Methods" "^.*set\\(Group\\|Replace\\)?Method(\"\\(.+\\)\"," 2)
;;     ;; ;;[ ]*\\(signature=\\)?(\\(.*,?\\)*\\)," 1)
;;     ;; ;;
;;     ;; ;;("Other" "^\\(.+\\)\\s-*<-[ \t\n]*[^\\(function\\|read\\|.*data\.frame\\)]" 1)
;;     ;; ("Package" "^.*\\(library\\|require\\)(\\(.*\\)," 2)
;;     ;; ("Data" "^\\(.+\\)\\s-*<-[ \t\n]*\\(read\\|.*data\.frame\\).*(" 1)))
;;     ))



;; (defun ess-imenu-gretl (&optional arg)
;;   "Gretl Language Imenu support for ESS."
;;   (interactive)
;;   (setq imenu-generic-expression gretl-imenu-generic-expression)
;;   (imenu-add-to-menubar "Imenu-gretl"))


;; (defun ess-imenu-gretl (&optional arg)
;;   "Gretl Language Imenu support for ESS."
;;   (interactive)
;;   (setq imenu-generic-expression gretl-imenu-generic-expression)
;;   (imenu-add-to-menubar "Imenu-jl"))

;; (fset 'ess-imenu-R 'ess-imenu-S)

(provide 'ess-gretl)
;; (provide 'ess-gretl)
