;;;; assignment3.asd

(asdf:defsystem #:assignment3
  :description "Implementation of assignment 3."
  :author "Raffael Botschen <raffael.botschen@uzh.ch>"
  :license  "No license specified."
  :version "0.0.1"
  :serial t
  :components ((:file "package")
               (:file "assignment3"))
  :build-operation "program-op"
  :build-pathname "C:/Users/raffa/portacle/projects/assignment3"
  :entry-point "assignment3::main")
