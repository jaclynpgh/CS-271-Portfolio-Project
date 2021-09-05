TITLE Programming Assignment  Designing Low-Level I/O procedures  (Proj6_mannja.asm)

; Author: Jaclyn Sabo
; Last Modified: 3/13/21
; OSU email address: mannja@oregonstate.edu
; Course number/section:   CS271 Section 400 W2021
; Project Number:    6             Due Date: 3/14/21 enacted grace days to be due 3/16/21
; Description: Program using macros where the user inputs 10 signed decimal integers that are small enough to fit into a 32 bit register.
; After numbers are entered, they are converted from ASCII to their numeric representation in order to validate then they are converted
; back to ASCII in order to display a list of numbers, as well as the sum and average of the numbers.

INCLUDE Irvine32.inc

; constants
ARRAYSIZE = 10		; size of array


; macros
;-------------------------
; mGetString
; Prompts user, gets user input, as well as the size and length of their input
; Preconditions: use EDX, ECX, EAX
; Receives:	
;			mdisplayString = macro to display string
;			prompt	= string to be displayed
;			input = user input
;			size = size of user input
;			stringLength = length of user input
; Returns:	user input
;---------------------------;-------------------------

mGetString MACRO prompt, input, size, stringLength
	; display prompt
	push	EDX
	push	ECX
	push	EAX
	mdisplayString prompt

	;get user input and size and length of input
	mov		EDX, input
	mov		ECX, size
	call	ReadString
	mov		stringLength, EAX

	pop		EAX
	pop		ECX
	pop		EDX
ENDM

;-------------------------
; mDisplayString
; Displays a string
; Preconditions: use EDX
; Receives:	
;			buffer = a string
; Returns:	displays a string
;---------------------------;-------------------------
mDisplayString MACRO buffer
	push	EDX
	mov		EDX, buffer
	call	WriteString
	pop		EDX
ENDM

.data
intro1			BYTE	"Programming Assignment 6: Desiging low-level I/O procedures",13,10
				BYTE	"Written by: Jaclyn Sabo",13,10,13,10,0
intro2			BYTE	13,10,"Please provide 10 signed decimal integers.",13,10
				BYTE	"Each number needs to be small enough to fit inside a 32 bit register. After you have finished inputting the",13,10
				BYTE	"raw numbers, I will display a list of the integers, their sum, and their average value.",13,10,13,10,0
prompt1			BYTE	"Please enter a signed number: ",0
error			BYTE	"ERROR: You did not enter a signed number or your number was too big.",13,10,0
display1		BYTE	13,10,"You entered the following numbers: ",13,10,0
comma			BYTE	", ",0
display2		BYTE	13,10,"The sum of these numbers is: ",0
display3		BYTE	13,10,13,10,"The average of these numbers is: ",0
goodbye			BYTE	13,10,13,10,"Thanks for partaking in another one of my programs! This was a tough one! See you next term!",13,10,0
inputArray		SDWORD	ARRAYSIZE DUP(0)	; array of 10 user numbers
userInput		BYTE	32   DUP(0)			; user input
stringLength	DWORD	?					; length of user input
userNum			SDWORD	?					; converted user number
average			DWORD	?					; average of user inputs
sum				DWORD	?					; sum of user inputs

.code
main PROC
	; introduce the program
	push	offset intro1	; 12
	push	offset intro2	; 8
	call	introduction	
	
	 ; read and validate input
	push	stringLength		; 32
	push	offset	prompt1		 ;28
	push	SIZEOF	userInput	; 24
	push	offset  userInput	; 20
	push	offset	error		; 16
	push	offset	inputArray	; 12
	push	ARRAYSIZE			; 8
	call	readVal

	; display user input in an array by calling a writeVal subprocedure
	push	userNum				; 28
	push	offset	userInput	; 24
	push	offset	display1	; 20
	push	offset	comma		; 16
	push	offset	inputArray	; 12
	push	ARRAYSIZE			; 8
	call	displayList


	; calculate sum and average
	push	offset	average		; 36
	push	offset	sum			; 32
	push	userNum				; 28
	push	offset	userInput	; 24
	push	offset	display3	; 20 average
	push	offset  display2	; 16 sum
	push	offset	inputArray	; 12 
	push	ARRAYSIZE			; 8 
	call	calculate

	; end program
	push	offset goodbye		; 8
	call	farewell			; display a farewell message 


	Invoke ExitProcess,0	; exit to operating system
main ENDP
;-------------------------
; INTRODUCTION
; Procedure to introduce the program.
; Preconditions: intro 1 and intro2 are strings of type BYTE
; Postconditions: none
; Receives:	from system stack:
;			[EBP+12] = intro1, introduces the program title and name of programmer
;			[EBP+8] = intro2, describes the program
; Returns:	none
;---------------------------;-------------------------
introduction	PROC
	push	EBP	
	mov		EBP, ESP
	push	EDX
	mDisplayString [EBP+12]
	mDisplayString [EBP+8]
	pop		EDX
	pop		EBP
	ret		8

introduction ENDP
;-------------------------
; readVal
; Procedure to read user input numbers, validate the numbers, convert the ASCII digits to it's numeric representation,
; and store values in an array, number must fit into a 32-bit register
; Preconditions: ARRAYSIZE is set as a constant, array is initialized
; Postconditions: registers changed EAX, EBX, ECX, ESI, EDI, EDX
; Receives:	 
;			mGetString = macro to display prompt get user input as well as size of and length of their input
;			 [EBP+8] = ARRAYSIZE constant, length of array
;			 [EBP+12] = inputArray, array (list)
;		     [EBP+16] = erro message
;			 [EBP+20] = userInput as BYTE
;			 [EBP+24] = SIZEOF userInput
;			[EBP+28] =	prompt to enter number
;			[EBP+32] =	length of string stored from macro
; Returns:	array with numeric inputs
;---------------------------
readVal PROC
	push	EBP
	mov		EBP, ESP
	mov		EDI, [EBP+12]	; moves array into EDI
	mov		ECX, [EBP+8]	; moves ARRAYSIZE into ECX

	_fillLoop:
	mGetString [EBP+28], [EBP+20], [EBP+24], [EBP+32]	; prompt, user input, and size, and length of user input
	push	ECX
	mov		ECX, [EBP+32]		; move length into ECX
	mov		ESI, [EBP+20]		; move user input to ESI
	mov		EBX, 0
	cld

	
	; check if input is in correct range in ASCII table
	_checkChar:
		mov		EAX, 0
		lodsb
		cmp		EAX, 48			; "0" = 48 in  simple.wikipedia.org/wiki/ASCII 
		jl		_checkSign
		cmp		EAX, 57			; "9" = 57
		jg		_checkSign
		jmp		_convert

		; see if first character is signed
		_checkSign:
		cmp		ECX, [EBP+32]
		jne		_invalidNumber
		cmp		EAX, 43			; "+"
		je		_signedNumber
		cmp		EAX, 45			;"-"
		je		_signedNumber
		jmp		_invalidNumber

		_signedNumber:	; if signed, check next character in string
		dec		ECX
		jmp		_checkChar

		_convert:					; convert to numeric representation
		sub		EAX, 48
		add		EAX, EBX 
		jo		_invalidNumber		; jump if overflow is set
		cmp		ECX, 1
		je		_checkNegative		; if last digit, do not need to multiply
		push	EBX
		mov		EBX, 10				; check to see if value of EDX fits in 32 bit register by multiplying by 10
		mov		EDX, 0
		mul		EBX
		pop		EBX
		cmp		EDX, 0
		jne		_invalidNumber
		jmp		_checkNegative

		_invalidNumber:
		pop		ECX				
		mDisplayString [EBP+16]  ; error message
		jmp		_fillLoop

		_checkNegative:
		mov		EBX, EAX
		dec		ECX
		cmp		ECX, 0
		jg		_checkChar		; jump to check next character
		mov		ESI, [EBP+20]	; user input in ESI
		mov		EAX, 0
		lodsb
		cmp		EAX, 45			; if negative, multiply by -1 before storing in array
		jne		_addtoArray
		mov		EAX, -1
		imul	EBX
		mov		EBX, EAX

		_addtoArray:			; store in array
		pop		ECX
		mov		[EDI], EBX
		add		EDI, 4
		mov		EAX, 0
		dec		ECX
		cmp		ECX, 0
		jg		_fillLoop
		
	pop	ebp
	ret	32
readVal ENDP
;-------------------------
; DISPLAY ARRAYS
; Prodedure to display array.
; Preconditions: ARRAYSIZE as a constant, array is initialized, user has inputed 10 numbers, title and comma as a string,
;				writeVal as a subprocedure
; Postconditions: registers changed EAX, EBX, ECX, EDI
; Receives:
;			mDisplayString = macro to display a string
;			[EBP+8] = ARRAYSIZE
;			[EBP+12] = array 
;			[EBP+16] = comma
;			[EBP+20] = display title for numbers entered
;			[EBP+24] = user input as BYTE
;			[EBP+28] = converted user number as SDWORD
; Returns:	elements of an array displayed
;---------------------------
displayList PROC
	push	EBP	
	mov		EBP, ESP	
	mov		EDI, [EBP+12]	; moves array into ESI
	mov		ECX, [EBP+8]	; moves ARRAYSIZE into ECX

	mdisplayString [EBP+20]

	_displayLoop:
	mov		EAX, [EDI]
	push	[EBP+28]	 ; user number
	push	[EBP+24]	; user input
	push	EDI
	call	writeVal
	add		EDI, 4		; get next index
	cmp		ECX, 1
	je		_nextIndex

	mdisplayString [EBP+16]  ; adds comma to display between numbers
	
	_nextIndex:
	loop	_displayLoop
	call	Crlf

	pop		EBP
	ret		24

displayList	ENDP
;-------------------------
; CALCULATE SUM AND AVERAGE
; Prodedure to calculate the sum and average of user inputs
; Preconditions: ARRAYSIZE as a constant, array is initialized, user has inputed 10 numbers, titles as a string,
;				writeVal as a subprocedure
; Postconditions: registers changed EAX, EBX, ECX, EDI
; Receives:
;			mDisplayString = macro to display a string
;			[EBP+8] = ARRAYSIZE
;			[EBP+12] = array 
;			[EBP+16] = display title for sum
;			[EBP+20] = display title for numbers entered
;			[EBP+24] = user input as BYTE
;			[EBP+28] = converted user number as SDWORD
;			[EBP+32] = sum as DWORD
;			[EBP+36] = average as DWORD
; Returns:	displays sum and average of user inputs
;---------------------------
calculate PROC
	push	EBP	
	mov		EBP, ESP	
	mov		EDI, [EBP+12]	; moves array into ESI
	mov		ECX, [EBP+8]	; moves ARRAYSIZE into ECX
	mov		EAX, 0

	_sumList:
	mov		EBX, [EDI]
	add		EAX, EBX
	add		EDI, 4
	loop	_sumList

	mdisplayString [EBP+16]		; display sum prompt

	; get sum
	mov		EBX, [EBP+32]	 ; sum
	mov		[EBX], EAX

	push	[EBP+28]		; converted Num
	push	[EBP+24]		; user input
	push	EBX
	call	writeVal		; call to convert to string and display

	mdisplayString [EBP+20]		; display average prompt

	; get average
	mov		EDX, 0
	cdq
	mov		ECX, [EBP+8]
	idiv	ECX
	mov		EBX, [EBP+36]
	mov		[EBX], EAX

	push	[EBP+28]	; converted num
	push	[EBP+24]	; user input
	push	EBX
	call	writeVal	; call to convert to string and display

	pop		EBP
	ret		32

calculate ENDP
;-------------------------
; writeVal
; Subprodedure to write the value, converts a numeric SDWORD value to ASCII string in order to display
; Preconditions: ARRAYSIZE as a constant, array is initialized, 10 numeric values
; Postconditions: none
; Receives:
;			mDisplayString = macro to display a string
;			[EBP+24] = user input as BYTE
;			[EBP+28] = converted user number as SDWORD
;			[EBP+32] = sum as DWORD
;			[EBP+36] = average as DWORD
; Returns:	converted numeric SDWORD as ASCII string to calculate procedure and display procedure
;---------------------------
writeVal PROC
	push	EBP
	push	EDI
	push	ECX
	push	EBX
	push	EAX
	mov		EBP, ESP
	mov		EDI, [ebp + 28]			; user input
	mov		EBX, [ebp + 24]			; converted number

	; check for 0 
	mov		EAX, [EBX]				; if 0, do not need to convert	
	cmp		EAX, 0
	je		_zero

	mov		EBX, 1				; check sign flag by multiply by 1, 0 = positive, 1 = negative
	imul	EBX							
	js		_negative
	mov		EAX, 32				; if positive, do not display sign 32 = space
	jmp		_storeFirstChar

_negative:
	mov		EAX, 45			; 45 = "-" store negative sign to display in EAX

_storeFirstChar:
	stosb										
	mov		ECX, 1000000000			; divide by 10s

_checkSign:
	mov		EBX, [EBP + 24]			
	mov		EAX, [EBX]					
	mov		EBX, 1				
	imul	EBX							
	jns		_getDigits					; jump if no sign
	mov		EBX, -1					; else reset to negative than store
	imul	EBX

_getDigits:
	mov		[EBP + 32], EAX				
	cdq
	idiv	ECX						; divide by 10s up to ten place values (1000000000) until EAX (quotient) != 0, then convert
	cmp		EAX, 0
	jne		_convertToAscii	
	mov		EBX, 10
	mov		EAX, ECX
	cdq
	div		EBX
	mov		ECX, EAX
	jmp		_checkSign

	_convertToAscii:		; convert to ASCII
		add		EAX, 48
		stosb
		sub		EAX, 48

		mul		ECX
		sub		[EBP + 32], EAX				
		mov		EAX, ECX
		mov		ECX, 10
		div		ECX
		mov		ECX, EAX
		mov		EAX, [EBP + 32]
		cmp		ECX, 0
		je		_display
		div		ECX
		jmp		_convertToAscii

	_zero:
		add		EAX, 48		; store 0
		stosb
		sub		EAX, 48

_display:
	mov		EAX, 0
	stosb
	mdisplayString	[EBP + 28]	; converted SDWORD		

	pop			EAX
	pop			EBX
	pop			ECX
	pop			EDI
	pop			EBP
	ret			12
writeVal ENDP

;-------------------------
; FAREWELL
; Procedure that displays a farwell message.
; Preconditions: goodbye message as a string
; Postconditions: none
; Receives: mDisplayString = macro that displays a string
;			from stack, [EBP+8] = goodbye message
; Returns: none
;---------------------------
farewell PROC
	push	EBP	
	mov		EBP, ESP
	push	EDX
	mDisplayString [EBP+8]
	pop		EDX
	pop		EBP
	ret		4

farewell ENDP
	
END main