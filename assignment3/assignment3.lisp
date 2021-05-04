(in-package #:assignment3)


(defparameter *states* (make-hash-table :test 'equal)); Maps state names to corresponding class instances.
(defvar *current-state*) ; Holds current state of FSM.



(defclass state ()
  ((state-name
    :initarg :state-name
    :initform (error "Must supply a state name.")
    :reader state-name
    :documentation "Name of the state.")
   (state-description
    :initarg :state-description
    :reader state-description
    :documentation "Description of the state.")
   (is-end-state ; Future versions could use state-function instead for more complex behaviour.
    :initarg :is-end-state
    :initform nil
    :reader is-end-state
    :documentation "Flag to designate end state.")
   (state-function
    :initarg :state-function
    :accessor state-function
    :documentation "Function that represents this state's behaviour.")
   (transitions ; HT with transitions originating from this state
    :initarg :transitions
    :initform (make-hash-table :test 'equal)
    :accessor transitions
    :documentation "Transitions (by name) from this state")))


; Initializes state-function for each state.
(defmethod initialize-instance :after ((state state) &key)
  (setf (state-function state)
    (lambda () (format t "[~a] ~a~%" (state-name state) (state-description state)))))



; Hash the parameters to create a key -> circumvents issues with equality.
(defun make-key-from-parameters (parameters)
  (if (not parameters) (setf parameters (list nil))); handles parameterless transition
  (sxhash (sort parameters #'(lambda (x y) (< (sxhash x) (sxhash y))))))


; Get HT of transitions with name transition-name starting at state.
; Contains the actual transitions which can be identified by their input.
(defun state->transitions (state transition-name)
  (gethash transition-name (transitions state)))


; For a given transitions HT, find the actual transition as identified by their parameters.
(defun transitions->parameterized-transition (transitions parameters)
  (gethash (make-key-from-parameters parameters) transitions))
  

; Store the function transition in the HT of the state.
(defun register-transition (start-state transition command parameters)
  (if (not (gethash command (transitions start-state)))
	(setf (gethash command (transitions start-state)) (make-hash-table)))
  (setf (gethash (make-key-from-parameters parameters) (gethash command (transitions start-state))) transition))



; Used to create valid state names (without whitespace).
(defun create-state-classname (classname)
  (concatenate 'string "state" (write-to-string (sxhash classname))))


(defun register-state (name state)
  (setf (gethash name *states*) state))


(defun retrieve-state (name)
  (gethash name *states*))


; Defines new state and registers a new instance of it.
(defun define-and-register-state (name description &optional is-end-state)
  (let ((hashed-name (intern (create-state-classname name))))
    (eval `(defclass ,hashed-name (state) ()))
    (register-state name (eval `(make-instance ',hashed-name :state-name ,name :state-description ,description :is-end-state ,is-end-state)))))


(defun create-transition (end-state-name parameters description)
  (if (not parameters) (setf parameters (list nil))) ; handles parameterless transition
  (eval `(lambda () (format t "> ~a~%" ,description) (gethash ,end-state-name *states*))))


(defun create-and-register-transition (start-state-name end-state-name command parameters description)
  (let ((transition (create-transition end-state-name parameters description)))
    (register-transition (retrieve-state start-state-name) transition command parameters)))


; Takes a string and splits it to a list using the separator.
(defun split-to-list (string separator)
  (let ((split-list (uiop:split-string string :separator separator)))
    (remove-if (lambda (x) (= (length x) 0)) split-list)))


(defun trim-whitespace (string)
  (string-trim '(#\Space #\Newline #\Backspace #\Tab #\Linefeed #\Page #\Return #\Rubout) string))



; Defines a new state, with the name being the part of the string before the delimiter,
; and the description the part after the delimiter.
(defun parse-state (string delimiter &optional (trim t))
  (let (state-name state-description)
    (setf state-name (trim-whitespace (subseq string 0 (search delimiter string))))
    (setf state-description (subseq string (+ (length delimiter) (search delimiter string))))
    (if trim (setf state-description (trim-whitespace state-description)))
    (cond
      ((string= "*" (subseq state-name 0 1)) ; start state
        (define-and-register-state (subseq state-name 1) state-description)
        (setf *current-state* (retrieve-state (subseq state-name 1))))
      ((string= "+" (subseq state-name 0 1)) ; end state
        (define-and-register-state (subseq state-name 1) state-description t))
      (t
        (define-and-register-state state-name state-description)))))


; Parses a transition of the form "startState (transition param1 param2 ...) endState: Description".
(defun parse-transition (string)
  (let (start-state-name end-state-name command parameters description)
    (setf description (trim-whitespace (subseq string (1+ (position #\: string)))))
    (setf start-state-name (trim-whitespace (subseq string 0 (position #\( string))))
    (setf end-state-name (trim-whitespace (subseq string (1+ (position #\) string)) (position #\: string))))
    (let (input-splitted)
      (setf input-splitted (trim-whitespace (subseq string (1+ (position #\( string)) (position #\) string))))
      (setf input-splitted (split-to-list input-splitted " "))
      (setf command (car input-splitted))
      (setf parameters (cdr input-splitted)))
    (when (string= "" command)
      (format t "Parser: Skipping invalid transition: \"~a\"~%" string)
      (return-from parse-transition))
    (create-and-register-transition start-state-name end-state-name command parameters description)))



; Parses a FSM described in a .machine file.
(defun parse-machine-file (filepath)
  (with-open-file (stream filepath :external-format :utf-8)
    (let ((parsing-states nil) (parsing-transitions nil))
      (loop for line = (read-line stream nil) while line do
        (setf line (subseq line 0 (position #\# line)))
        (setf line (trim-whitespace line))
        (cond
          ((string= "[States]" line)
            (setf parsing-states t))
          ((string= "[Transitions]" line)
            (setf parsing-states nil)
            (setf parsing-transitions t))
          ((and parsing-states (/= (length line) 0))
            (parse-state line ":"))
          ((and parsing-transitions(/= (length line) 0))
            (parse-transition line)))))))


; Parses a FSM described in a .gfl file.
(defun parse-gfl-file (filepath)
  (with-open-file (stream filepath :external-format :utf-8)
    (let ((is-reading-state nil) (state ""))
      (loop for line = (read-line stream nil) while line do
        (setf line (subseq line 0 (position #\# line)))
        (cond
          ((and is-reading-state (or (string= line "") (char= #\Space (elt line 0))))
            (setf state (concatenate 'string state (string #\Newline) line)))
          (is-reading-state
            (parse-state state ":" nil)
            (setf state "")
            (setf is-reading-state nil)))
        (when (and (> (length line) 0) (char= #\@ (elt line 0)))
          (format t "reading state: ~a" line)
          (setf state (subseq line 1 (1+ (position #\: line))))
          (setf is-reading-state t))
        (if (and (> (length line) 0) (char= #\> (elt line 0)))
          (parse-transition (trim-whitespace (subseq line 1)))))
      (if is-reading-state
        (parse-state state ":" nil)))))



; Executes the transition from start state identified by the input
; of the form "transition param1 param2 ...".
(defun execute-transition (start-state input)
  (let (command parameters)
    (let ((split-list (split-to-list input " ")))
      (setf command (car split-list))
      (setf parameters (cdr split-list)))
    (let ((transitions (state->transitions start-state command)) (transition nil))
      (when (not transitions)
        (format t "! invalid input, please try again~%")
        (return-from execute-transition))
      (setf transition (transitions->parameterized-transition transitions parameters))
      (if (not transition)
        (setf transition (transitions->parameterized-transition transitions (list "*"))))
      (when (not transition)
        (format t "! invalid parameters, please try again~%")
        (return-from execute-transition))
      (setf *current-state* (funcall transition)))))



; Entrypoint of this project.
; Read in FSM from file at specified position, and executes it.
(defun main ()
  
  (let ((filepath (car (uiop:command-line-arguments))))
    
    ; Check existence of file.
    (when (not (probe-file filepath))
      (format t "Could not find file ~a" filepath)
      (return-from main))
    
    ; Initialize FSM.
    (let ((filetype (subseq filepath (position #\. filepath))))
      (if (string= filetype ".machine")
        (parse-machine-file filepath)
        (parse-gfl-file filepath))))


  ; Listen for inputs.
  (loop
    (funcall (state-function *current-state*))
    (if (is-end-state *current-state*)
      (return-from main))
    (execute-transition *current-state* (read-line))))