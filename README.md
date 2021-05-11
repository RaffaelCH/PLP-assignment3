# assignment3


### _Raffael Botschen <raffael.botschen@uzh.ch>_

Implementation of assignment 3 of the course PLP at UZH, written in Common Lisp.
Parses a FSM from a file and allows the user to execute it.


## Compilation and Usage

To compile it, install sbcl (or a CL compiler of your choice).
Load quicklisp.

Execute the following commands (substituting in your filepath) to load the project and compile it:

`(load "C:\\path\\to\\project\\assignment3\\assignment3.asd")`

`(ql:quickload "assignment3")`

`(sb-ext:save-lisp-and-die #p"assignment3.exe" :toplevel #'assignment3::main :executable t)`

Call it using: `"C:/path/to/executable/assignment3.exe" "C:/path/to/FSM/file/file.gfl"`



## FSM File Definition


### .machine Files
The [States] section describes the available states.
Each line contains the name of a state, followed by a colon and a short description.
Both the name and description can consist of multiple words. One state is preceeded by an asterisk (*),
indicating that it is the initial state. One or more states are preceeded by a plus sign (+), indicating any states which end the program.
Any whitespace before or after the name or description should be stripped upon parsing.
The [Transitions] section specifies the possible transitions of the state machine.
Each line conforms to the format

`A (input) B: description`

, where `A` and `B` are states, and `input` is the expected input to switch states.
Again, a description is provided after the colon, and any whitespace around the state names, expected input or description should be stripped.
The input itself consists of one word, the command, and any number of parameters following, each separated by whitespace.
The parser should ignore blank lines and anything after an octothorpe (#).
- The sections [States] and [Transitions] will appear in this order and only once, each.
- You can assume that : , ( and ) are only used as delimiters and never in the names of states,inputs or input parameters.


### .gfl Files
.gfl files are somewhat similar to .machine files, but^instead of having two spearate sections containing one-line definitions for states and transitions,
.gfl files use the two characters @ and > to indicate lines where these definitions begin.
State and transition definitions may appear in any order.

State definitions can stretch multiple lines and consist of the following parts:
- An @ sign at the beginning of a line is a prefix marking the beginning of a state definition.
  Exactly one state definition in the game file must start with @* to indicate the initial gamestate and one or more states must use the @+ prefix to indicate end states of the game.
- The prefix is followed by the state ID followed by a colon (:) and newline.
  State IDs must be unique within a game file and can contain any except the following characters: @ : *
- After this first line, there can be zero or more lines which are either empty or start with at least one space. These lines represent thegame screenshown in this state.
  Their content should simply be printed on screen when the state is entered. The game screen can contain any characters (as long as the lines are empty or start with a space).

Transitions are also very similar to the previous specification.
However, instead of being in their own section, transitions are prefixed with a > sign.
So the syntax for a transition canbe described as:

`>State1 (Command param1 param2) State Two: What happens during the transition.`

If invalid commands or parameters are entered, the behavior should be the same as previously (i.e., print an error and return to the same state),
however there exists one extension over the oldsyntax, namely that a command can be followed by a * sign instead of additional parameters, i.e

`>Select (Choose*) Select: Invalid beverage selected.`

Such a transition shall be used as a fall back if all other parameters for this command are invalid.
Until the first colon,  you can assume that the characters ( ) : * are only used for the transition syntax, but not within state, command or parameter names.
The description after the colon can contain any characters.