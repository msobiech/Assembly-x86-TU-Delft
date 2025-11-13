.text

output: .asciz "\x1b[%dm\x1b[48;5;%dm\x1b[38;5;%dm%c"  # \x1b[%dm (CSI sequence code [blinking,fading etc.]) \x1b[48;5;%dm (background color) \x1b[38;5;%dm (foreground color) %c the character to print

.include "final.s"

.global main

# ************************************************************
# Subroutine: decode                                         *
# Description: decodes message as defined in Assignment 3    *
#   - 2 byte colors                                          *
#   - 4 byte index                                           *
#   - 1 byte amount                                          *
#   - 1 byte character                                       *
# Parameters:                                                *
#   first: the address of the message to read                *
#   return: no return value                                  *
# ************************************************************
decode:
	# prologue
	pushq	%rbp 					# push the base pointer (and align the stack)
	movq	%rsp, %rbp				# copy stack pointer value to base pointer

	pushq	%r12					#push %r12-15 onto the stack to retrieve them later
	pushq	%r13
	pushq	%r14
	pushq	%r15

	movq	%rdi, %r15	 			# copy the address of the message to %r15 for later usage
	movq	$0, %r14				# clear the %r14 (it is going to hold address of the currently read piece of the message)
	movq	$0, %r12				# clearing r12. It will hold our ANSI code
	movq 	$0, %r13				# clearing r13. It will hold our number of prints 
	movq 	$0, %rsi				# clearing registers that are later used to pass the colors and other attributes to printf(without it the first printf didnt work correctly)
	movq 	$0, %rdx			
	movq 	$0, %rcx
	movq	$0, %r12				# setting the r12 to our current text modifier
	loop:
		shlq	$3, %r14			# multiply the %r14 by 8. If it holds the index from which we should read then multiplied by 8 (8 bytes is every message) 
		addq    %r15, %r14			# and incremented by the %r11 it will contain the beginning of the read message
		

		
		movb	+1(%r14), %r13b 	# setting the r13 to our current number of prints
		
		movb	+6(%r14), %r11b		# copying value of background color to r11 because for cmpb we need at least one not memory address
		cmpb 	%r11b, +7(%r14)		# check if background and foreground are the same
		jne 	notsame			# if they are not the same we can proceed to print
		


		cmpb	$0, %r11b			# if they are 0 we reset
		je		reset

		cmpb    $37, %r11b 			# if they are 37 we stop blinking
		je		stopblink

		cmpb    $42, %r11b			# if they are 42 we enable bold
		je		bold

		cmpb    $66, %r11b			# if they are 66 we enable faint
		je		faint

		cmpb    $105, %r11b			# if they are 105 we enable conceal
		je		conceal

		cmpb    $153, %r11b			# if they are 153 we reveal(disable the conceal)
		je		reveal

		cmpb    $182, %r11b			# if they are 182 we enable blinking
		je		blink

		reset:
			movq $0, %r12			# moving correct value of the CSI sequence to r12
			jmp printloop
		stopblink:
			movq $25, %r12 #25		# moving correct value of the CSI sequence to r12
			jmp printloop
		bold:
			movq $1, %r12 #1		# moving correct value of the CSI sequence to r12
			jmp printloop
		faint:
			movq $2, %r12 #2		# moving correct value of the CSI sequence to r12
			jmp printloop
		conceal:
			movq $8, %r12 #8		# moving correct value of the CSI sequence to r12
			jmp printloop
		reveal:
			movq $28, %r12 #28		# moving correct value of the CSI sequence to r12
			jmp printloop
		blink:
			movq $6, %r12 #6		# moving correct value of the CSI sequence to r12
			jmp printloop

		#background	+6(%r14)
		#text color	+7(%r14)

		notsame:
			pushq $0				# pushing the last working background color 
			movb +6(%r14), %r10b	
			movb %r10b, (%rsp)
			pushq $0				# pushing the last foreground background color 
			movb +7(%r14), %r10b
			movb %r10b, (%rsp)
		
		printloop:
			cmpb	$0, %r13b		# if the number of prints is 0 then we should jump to the next character
			jle		next		

			movq	$0, %rsi
			movq	$output, %rdi	# putting the message that contains only one char for printf
			movq	%r12, %rsi		# move the CSI sequence code as first argument
			movb	(%rsp), %dl   # move the background color as second argument
			movb	+8(%rsp), %cl	# move the text color as third argument
			movb	(%r14), %r8b	# we move our letter to 1byte version of r8( 4th argument) to print it	
			
			movq	$0, %rax		# no SSE registers will be used
			call 	printf			# printing the letter

			decb	%r13b			# decrementing our counter of number of prints left
			jmp printloop			# jumping back to the beggining of the loop
		next:
		movl	+2(%r14), %r14d 	# setting the %r14 to the new jump index
		cmpl	$0, %r14d			# if the next jump address is bigger than 0 then we jump. Else we end our subroutine
		jg		loop
	
	# epilogue
	movq 	%rbp, %rsp
	addq	$32, %rsp				# setting the rsp to correct place so we can retrieve our registers
	popq	%r15					# retrieving the register values
	popq	%r14
	popq	%r13
	popq	%r12

	movq	%rbp, %rsp				# clear local variables from stack
	popq	%rbp					# restore base pointer location 
	ret

main:
	pushq	%rbp 					# push the base pointer (and align the stack)
	movq	%rsp, %rbp				# copy stack pointer value to base pointer

	movq	$MESSAGE, %rdi			# first parameter: address of the message
	call	decode					# call decode

	popq	%rbp					# restore base pointer location 
	movq	$0, %rdi				# load program exit code
	call	exit					# exit the program

