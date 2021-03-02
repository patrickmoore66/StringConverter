TITLE Proj6_moorpatr     (Proj6_moorpatr.asm)

; Author: Patrick Moore
; Last Modified: 12/6/2020
; OSU email address: patrick.moore@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6               Due Date: 12/6/2020
; Description: This program takes 10 signed integers from the user, converts them to a string, stores them in an array, 
;			   and then converts the integers into a string to display, and finds
;			   their sum, and average. Has a mGetString macro to get a string from the user and  mDisplayString to
;			   display a string. Has a ReadVal procedure that gets user input, converts it to a numerical value, and 
;			   stores it in memory. Has a WriteVal procedure that takes a numerical value and displays a string. 
;			   Has a FindSum procedure to find the Sum of user entries, and a FindAvg procedure to find the average 
;			   of the user entries rounded down. (floor)

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Displays a prompt, receives a string from the user, stores string and the length of the string at given memory
; locations. 
;
; Preconditions: parameters are correctly initialized and filled
;
; Receives:
; promptAddr	= Prompt address to be displayed to user
; arrayAddr		= location in memory where user input will be stored
; maxChars		= The maximum number of characters the user can input
; stringLenAddr = location in memory where the number of characters the user input will be stored
; 
;
; returns: 
; [arrayAddr]	  = a string of the user's entry
; [stringLenAddr] = the number of characters the user entered
; -----------------------------------------------------------------------------------
mGetString	MACRO	promptAddr:REQ, arrayAddr:REQ, maxChars:REQ, stringLenAddr:REQ
;Preserve registers used
	PUSH	EDX
	PUSH	ECX
	PUSH	EAX

;Print prompt
	mDisplayString promptAddr

;Call ReadString, saving user entered string at arrayAddr
	MOV		EDX, arrayAddr
	MOV		ECX, maxChars
	CALL	ReadString				
	CALL	Crlf

	;Save the length of the user entry to memory
	MOV		[stringLen], EAX

	;Restore registers used
	POP 	EAX
	POP		ECX
	POP		EDX
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Displays string at given array address
;
; Preconditions: string_addr is the location in memory where a null terminated string is located
;
; Receives:
; string_addr = location in memory of string to be displayed
; 
;
; returns: string at string_addr is printed
; ---------------------------------------------------------------------------------
mDisplayString	MACRO		string_addr:REQ
	;Preserve register used
	PUSH	EDX

	;Call WriteString
	MOV		EDX, string_addr
	CALL	WriteString

	;Restore register used
	POP		EDX
ENDM

;Constant Values
NUMVALUES = 10


.data

title_msg		BYTE	"CS 271 Assignment 6: String Primitives and Macros by Patrick Moore",0
intro_msg1		BYTE	"Please provide ",0
intro_msg2		BYTE	" signed decimal integers", 0
temp_val		SDWORD	?
intro_msg3		BYTE	"Each number needs to be small enough to fit inside a 32 bit register. After you have finished inputting the raw numbers I will display a list of the integers, their sum, and their average value.",0
user_prmpt		BYTE	"Please enter a signed number:", 0
sum_list		DWORD   NUMVALUES DUP(?)
user_entry		BYTE	20 DUP(0)
stringLen		DWORD	?
error_msg		BYTE	"ERROR: You did not enter a signed number or your number was too big.", 0
user_entry_msg	BYTE	"You entered the following numbers: ", 0
entry_spacer	BYTE	", ",0
sum_int			DWORD	?
sum_msg			BYTE	"The sum of these numbers is: ", 0
average_int		DWORD	?
average_msg		BYTE	"The rounded down (floor) average is: ", 0
goodbye_msg		BYTE	"Thank you for using my program!",0


.code
main PROC

	;Display Title
	mDisplayString OFFSET title_msg
	CALL	Crlf
	CALL	Crlf

	;Display intro
	mDisplayString OFFSET intro_msg1

	MOV		temp_val, NUMVALUES									;Can't use WriteInt, so this is the workaround to modulary display NUMVALUES
	PUSH	OFFSET	temp_val
	CALL	WriteVal

	mDisplayString OFFSET intro_msg2
	CALL	Crlf

	mDisplayString OFFSET intro_msg3
	CALL	Crlf
	CALL	Crlf

	;Call ReadValue to get user entries
	PUSH	TYPE sum_list
	PUSH	OFFSET	error_msg
	PUSH	OFFSET	sum_list
	PUSH	NUMVALUES
	PUSH	OFFSET	user_prmpt
	PUSH	OFFSET	user_entry
	PUSH	SIZEOF	user_entry
	PUSH	OFFSET	stringLen
	CALL	ReadVal

	;Display user entry message
	mDisplayString	OFFSET user_entry_msg
	CALL	Crlf

	;Loop to display the number of user entered integers
	MOV		ECX, NUMVALUES
	MOV		ESI, OFFSET	sum_list

_display_value:

	;Call WriteVal to display Array of user entered integers
	PUSH	ESI
	CALL	WriteVal

	CMP		ECX, 1
	JE		_end

	mDisplayString	OFFSET entry_spacer

	ADD		ESI, TYPE sum_list
	LOOP	_display_value

_end:
	;New line after values
	CALL	Crlf

	;Call FindSum to calculate the sum of the user entries
	PUSH	TYPE sum_list
	PUSH	OFFSET sum_int
	PUSH	OFFSET sum_list
	PUSH	NUMVALUES
	CALL	FindSum

	;Display Sum message
	mDisplayString	OFFSET sum_msg

	;Display results of FindSum stored in sum_int
	PUSH	OFFSET sum_int
	CALL	WriteVal
	CALL	Crlf

	;Call FindAvg to the calculate the average of the user entries
	PUSH	OFFSET	average_int
	PUSH	sum_int
	PUSH	NUMVALUES
	CALL	FindAvg

	;Display Average message
	mDisplayString	OFFSET average_msg

	;Display results of FindAvg stored in average_int
	PUSH	OFFSET average_int
	CALL	WriteVal
	CALL	Crlf
	CALL	Crlf
	CALL	Crlf

	;Display goodbye message
	mDisplayString	OFFSET goodbye_msg
	CALL	Crlf
	CALL	Crlf


	Invoke ExitProcess,0	; exit to operating system
main ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; Gets user input, validates input, converts string input to numerical values, and stores the values in memory
;
; Preconditions: error_msg points to a string message. sumList points to a location in memory with at least NUMVALUES 
; spaces for user input. NUMVALUES has been declared. user_prmp points to a string message. userEntry points to a string
; with enough space for the maximum valule allowed depending on data type. stringLen points to a location in memory where
; a decimal value denoting the length of the user's input can be stored. Order of labels is due to LOOP restrictions.
;
; Postconditions: All registers are restored at the end of the procedure
;
; Receives:
; [ebp+36] = TYPE sumList		- Type of the array where entries will be stored, used to increment through array
; [ebp+32] = OFFSET error_msg	- Location in memory for a message to be displayed when a user's entry is invalid
; [ebp+28] = OFFSET sumList		- Location in memory of an array of SDWORDS where the user's entries are stored numerically
; [ebp+24] = NUMVALUES			- Constant value representing the number of user entries.
; [ebp+20] = OFFSET user_prmpt	- Location in memory of a message prompting the user to enter a number
; [ebp+16] = OFFSET userEntry	- Location in memory to store the user's entry as a string
; [ebp+12] = SIZEOF userEntry	- Value of the maximum buffer allowed for ReadString
; [ebp+8] =	OFFSET stringLen	- Location in memory for storing the length of the user's string entry 
; 
;
; returns: 
; [ebp+8]	= OFFSET stringLen - [stringLen] = the length of the user entry
; [ebp+16]  = OFFSET userEntry - Now points to a string containing the user's entry characters
; [ebp+28]  = OFFset sumList   -Now points to an array of SDWORDS with the user's entries stored as decimal values
; ---------------------------------------------------------------------------------
ReadVal		PROC
	LOCAL	sign:SDWORD
	;Preserve registers used
	PUSH	ESI
	PUSH	EDI
	PUSH	ECX
	PUSH	EDX
	PUSH	EBX
	PUSH	EAX
	PUSHFD

	;set up outside loop counter to equal total number of user entries(10)
	MOV		ECX, [EBP+24]
	MOV		EDI, [EBP+28]
	MOV		EAX, 0
	CLD

_getChars:
	;Get entry from the user
	mGetString [EBP+20], [EBP+16], [EBP+12], [EBP+8]

	;set counter for inner loop to validate characters in string, move now full user_entry to ESI
	MOV		ESI, [EBP+8]						
	MOV		EBX, [ESI]
	MOV		ESI, [EBP+16]

	;Check first character for a "+" or "-"
	LODSB
	MOV		EDX, 0						;Clear EDX to accumulate value
	CMP		AL, 43						;Check for "+"
	JE		_plus
	CMP		AL, 45						;Check for "-"
	JE		_minus
	JMP		_firstChar

_validateChars:							;check that each digit entered is valid
	LODSB

_firstChar:
	CMP		AL, 48						;Check < ASCII "0"
	JL		_invalid
	CMP		AL, 57						;Check > ASCII "9"
	JG		_invalid
	SUB		AL, 48
	PUSH	EBX							;Preserve so we can use EBX as a counter for number of places

_getZeroes:								;Add the correct number of zeroes to the value
	CMP		EBX, 1
	JE		_endZeroes
	IMUL	EAX, 10
	JO		_invalid
	DEC		EBX
	JMP		_getZeroes

_endZeroes:								;value is correct, add to accumulator in EDX
	POP		EBX
	ADD		EDX, EAX
	JO		_invalid					;check overflow flag
	MOV		EAX, 0						;Clear EAX for next char
	DEC		EBX
	CMP		EBX, 0
	JG		_validateChars

	;Check if value is negative
	CMP		sign, 1
	JE		_neg

_add_value:								;Add user entry to list of values entered by user, increment EDI for next value

	MOV		[EDI], EDX
	ADD		EDI, [EBP+36]
	MOV		sign, 0						;reset sign variable for next entry
	LOOP	_getChars
	JMP		_end

_neg:									;Negates the final value
	NEG		EDX
	JMP		_add_value

_plus:									;handles if the user entry has a "+" sign
	DEC		EBX
	CMP		EBX, 0
	JG		_validateChars
	JMP		_invalid


_minus:									; Sets local variable sign to 1 if value is negative. 
	MOV		sign, 1
	DEC		EBX
	CMP		EBX, 0
	JG		_validateChars
	JMP		_invalid

_invalid:								;Display invalid message, jumps to get_chars to try again
	MOV		EDX, [EBP+32]

	mDisplayString	EDX

	CALL	Crlf
	MOV		EAX, 0
	JMP		_getChars

_end:									;Restore registers and return
	POPFD
	POP		EAX
	POP		EBX
	POP		EDX
	POP		ECX
	POP		EDI
	POP		ESI
	RET		32
ReadVal		ENDP


; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; Converts an SDWORD value to a string, then displays the string using the mDisplayString macro.
;
; Preconditions: The location in memory passed as a parameter is the address of an SDWORD containing a
; signed integer. 
;
; Postconditions: All used registers are restored
;
; Receives:
; [ebp+8] = Address of an SDWORD containing a signed integer in memory
; 
;
; returns: None
; ---------------------------------------------------------------------------------
WriteVal	PROC
	LOCAL	display_str[15]:BYTE, remainder_count:SDWORD

	;Preserve registers used
	PUSH	ESI
	PUSH	EDI
	PUSH	EAX
	PUSH	EDX
	PUSH	EBX
	PUSHFD

	;set up source, destination, and accumulator, clear direction
	MOV		ESI, [EBP+8]
	LEA		EDI, display_str
	MOV		EDX, 0
	CLD

_new_entry:										;Load value, check if negative
	MOV		EAX, [ESI]
	CMP		EAX, 2147483647
	MOV		remainder_count, 0
	JA		_negative

_convert_int:									;Loops while the value is greater than or equal to than 10
	CMP		EAX, 10
	JL		_add_char
	CDQ
	MOV		EBX, 10
	IDIV	EBX
	CMP		EDX, 0
	JE		_save_remainder
	CMP		EAX, 10
	JGE		_save_remainder

_add_char:										;Convert number to ascii vale, add to string
	ADD		EAX, 48
	STOSB
	CMP		EDX, 0
	JE		_write_remainder

	;save the most immediate remainder
	MOV		EAX, EDX
	ADD		EAX, 48
	STOSB

_write_remainder:								;Pop saved remainders off the stack, convert to ascii, save into string
	CMP		remainder_count, 0
	JE		_end
	POP		EAX
	ADD		EAX,48
	STOSB
	DEC		remainder_count
	JMP		_write_remainder

_save_remainder:								;save the remainder on the stack
	PUSH	EDX
	INC		remainder_count
	JMP		_convert_int


_negative:										;converts a twos compliment to it's positive value, saves "-" char to string
	NEG		EAX
	PUSH	EAX
	MOV		AL, 45
	STOSB
	POP		EAX
	JMP		_convert_int

_end:
	;Null terminate the string
	MOV		EAX, 0
	STOSB

	;Display the string
	LEA		EDX, display_str

	mDisplayString	EDX

	;restore registers and return
	POPFD
	POP		EBX
	POP		EDX
	POP		EAX
	PUSH	EDI
	PUSH	ESI
	RET		4
WriteVal	ENDP

; ---------------------------------------------------------------------------------
; Name: FindSum
;
; Finds the sum of an array of SDWORDS, and stores the sum in memory.
;
; Preconditions: sum_list is an array of SDWORDS with values in memory. NUMVALUES is greater than -1. sum_int points
; tp a specific location in memory
;
; Postconditions: All used registers are restored
;
; Receives:
; [ebp+20] = TYPE sum_list	 - Type of source array of signed integers
; [ebp+16] = OFFSET sum_int	 -Address of a location in memory to store the sum
; [ebp+12] = OFFSET sum_list -Address of source array of signed integers
; [ebp+8] =	 NUMVALUES		 -Number of values in source array of signed integers
; 
;
; returns: 
; [ebp+16] = OFFSET sum_int = the sum of all values in the array sum_list
; ---------------------------------------------------------------------------------
FindSum		PROC
	;Establish stack frame
	PUSH	EBP
	MOV		EBP, ESP

	;Preserve used registers
	PUSH	ECX
	PUSH	ESI
	PUSH	EDI
	PUSH	EAX
	PUSH	EBX

	;Set up lood, source, and destination
	MOV		ECX, [EBP+8]
	MOV		ESI, [EBP+12]
	MOV		EDI, [EBP+16]
	MOV		EBX, 0
	MOV		[EDI],EBX

_loop:
	;Loop through array, adding each value in EAX as the accumulator
	MOV		EAX, [ESI]
	MOV		EBX, [EBP+20]
	ADD		[EDI], EAX
	ADD		ESI, EBX
	LOOP	_loop

	;Restore used registers
	POP		EBX
	POP		EAX
	POP		EDI
	POP		ESI
	POP		ECX
	POP		EBP
	RET		16

FindSum		ENDP

; ---------------------------------------------------------------------------------
; Name: FindAvg
;
; Finds the average of the list of user entries, rounding down (floor) for any remainders. 
;
; Preconditions: The sum of user entries has been calculated and saved in memory
;
; Postconditions: All used registers are restored
;
; Receives:
; [ebp+16] = OFFSET average_int - Address of a location in memory to store the average
; [ebp+12] = sum_int			- value of the sum of user entries
; [ebp+8]  = NUMVALUES			- Number of values in source array of signed integers
; 
; returns: 
; [average_int] = the average (the value of sum_int divided by NUMVALUES) of the user's entries 
; ---------------------------------------------------------------------------------
FindAvg		PROC
	;Set up Base pointer and preserve registers
	PUSH	EBP
	MOV		EBP, ESP

	PUSH	EAX
	PUSH	EDX
	PUSH	EBX
	PUSH	EDI

	;Set up destination, dividend, and divisor
	MOV		EDI, [EBP+16]
	MOV		EAX, [EBP+12]
	CDQ
	MOV		EBX, [EBP+8]

	;Divide, move result to destination
	IDIV	EBX
	MOV		[EDI], EAX

	;Restore registers and return
	POP		EDI
	POP		EBX
	POP		EDX
	POP		EAX
	POP		EBP
	RET		12
FindAvg		ENDP

END main
