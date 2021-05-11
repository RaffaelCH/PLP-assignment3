# assignment3

### _Raffael Botschen <raffael.botschen@uzh.ch>_

Implementation of assignment 3 of the course PLP in Common Lisp.
Parses a FSM from a file and allows the user to execute it.

## Compilation

To compile it, install sbcl (or a CL compiler of your choice).
Load quicklisp.

Execute the following commands (substituting in your filepath) to load the project and compile it:

`(load "C:\\path\\to\\project\\assignment3\\assignment3.asd")`

`(ql:quickload "assignment3")`

`(sb-ext:save-lisp-and-die #p"assignment3.exe" :toplevel #'assignment3::main :executable t)`

Call it using: `"C:/path/to/executable/assignment3.exe" "C:/path/to/FSM/file/file.gfl"`
