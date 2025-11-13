.text

output: .asciz "%c"  #"%#010x" <- for hex print
authors:    .asciz "\nNames: Maksymilian Sobiech and Jokūbas Jasiūnas\nNetIDs: msobiech and jjasiunas\nAssignment 3: Decoder\n"
.include "final.s"

.global main

# ************************************************************
# Subroutine: decode                                         *
# Description: decodes message as defined in Assignment 3    *
#   - 2 byte unknown                                         *
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

	loop:
		shlq	$3, %r14			# multiply the %r14 by 8. If it holds the index from which we should read then multiplied by 8 (8 bytes is every message) 
		addq    %r15, %r14			# and incremented by the %r11 it will contain the beginning of the read message
		

		movb	(%r14), %r12b		# setting the r12 to our current character that we will later print
		movb	+1(%r14), %r13b 	# setting the r13 to our current number of prints
		movl	+2(%r14), %r14d 	# setting the %r14 to the new jump index
		
		
		
		printloop:
			cmpb	$0, %r13b		# if the number of prints is 0 then we should jump to the next character
			jle		next		

			movb	%r12b, %sil		# we move our letter to 1byte version of rsi to print it	
			movq	$output, %rdi	# putting the message that contains only one char for printf
			movq	$0, %rax		# no SSE registers will be used
			call 	printf			# printing the letter

			decb	%r13b			# decrementing our counter of number of prints left
			jmp printloop			# jumping back to the beggining of the loop
		next:

		cmpl	$0, %r14d			#if the next jump address is bigger than 0 then we jump. Else we end our subroutine
		jg		loop
	
	# epilogue
	
	popq	%r15					#retrieving the register values
	popq	%r14
	popq	%r13
	popq	%r12

	movq	%rbp, %rsp				# clear local variables from stack
	popq	%rbp					# restore base pointer location 
	ret

main:
	pushq	%rbp 					# push the base pointer (and align the stack)
	movq	%rsp, %rbp				# copy stack pointer value to base pointer

	movq 	$0, %rax				#printing the authors in the beginning
	movq 	$authors, %rdi
	call 	printf

	movq	$MESSAGE, %rdi			# first parameter: address of the message
	call	decode					# call decode

	popq	%rbp					# restore base pointer location 
	movq	$0, %rdi				# load program exit code
	call	exit					# exit the program

