.text

valid: .asciz "valid"
invalid: .asciz "invalid"

#.include "neighboringValid.s"
.include "basic.s"
#.include "basicInvalid.s"
#.include "test2.s"
#.include "test.s"

.global main

# *******************************************************************************************
# Subroutine: check_validity                                                                *
# Description: checks the validity of a string of parentheses as defined in Assignment 6.   *
# Parameters:                                                                               *
#   first: the string that should be check_validity                                         *
#   return: the result of the check, either "valid" or "invalid"                            *
# *******************************************************************************************



check_validity:
	# < - 60
	# > - 62
	# ( - 40 
	# ) - 41 
	# { - 123
	# } - 125
	# [ - 91
	# ] - 93
	# prologue
	pushq	%rbp 				# push the base pointer (and align the stack)
	movq	%rsp, %rbp			# copy stack pointer value to base pointer

	pushq	%r12
	pushq	%r13
	leaq	(%rdi), %r12		# loading the message to r12
	
	pushq	$0;					#-24(%rbp)  holding counter for ()
	pushq	$0; 				#-32(%rbp)	holding counter for {}
	pushq	$0;	 				#-40(%rbp) holding counter for []
	pushq	$0; 				#-48(%rbp) holding counter for <>

	
	loop:
		movb	(%r12), %r13b	# moving the current character to r13b
		cmpb	$0, %r13b		# checking if the character is the terminator
		je 		done			# if it is terminator then we end the loop
		
		cmpb	$40, %r13b 		# if(message[i]=='(')
		je	roundopen	
		
		cmpb	 $41, %r13b		# if(message[i]==')')
		je	roundclose
	
		cmpb	$91 ,%r13b 		# if(message[i]=='[')
		je	boxopen

		cmpb	$93, %r13b  	# if(message[i]==']')
		je	boxclose
		
		cmpb	$60, %r13b 		# if(message[i]=='<')
		je	angleopen

		cmpb	$62, %r13b 		# if(message[i]=='>')
		je	angleclose

		cmpb	$123, %r13b 	# if(message[i]=='{')
		je	curlyopen

		cmpb	$125, %r13b 	# if(message[i]=='}')
		je	curlyclose

		jmp wrong

		# value on top of the stack says which type of brackets are expected to be closed next

		roundopen:
			pushq	$1				# push the expected type of bracket to be closed next
			incq -24(%rbp)			# if it is a new open bracket then we increment its counter
			jmp next				

		roundclose:
			popq	%r11			# we check which bracket we are expecting to close
			cmpq	$1, %r11		
			jne		wrong			# if it is different then we say it is wrong

			cmpq $0, -24(%rbp)		# if there was not enough opening brackets before the closing then the parentheses is wrong
			je wrong
			decq -24(%rbp)			# otherwise we decrement the counter
			jmp next


		curlyopen:
			pushq	$2				# push the expected type of bracket to be closed next
			incq -32(%rbp)			# if it is a new open bracket then we increment its counter
			jmp next

		curlyclose:
			popq	%r11			# we check which bracket we are expecting to close
			cmpq	$2, %r11		
			jne		wrong			# if it is different then we say it is wrong

			cmpq $0, -32(%rbp)		# if there was not enough opening brackets before the closing then the parentheses is wrong
			je wrong
			decq -32(%rbp)			# otherwise we decrement the counter
			jmp next

		boxopen:
			pushq	$3				# push the expected type of bracket to be closed next
			incq -40(%rbp)			# if it is a new open bracket then we increment its counter
			jmp next

		boxclose:
			popq	%r11			# we check which bracket we are expecting to close
			cmpq	$3, %r11		
			jne		wrong			# if it is different then we say it is wrong	
			
			cmpq $0, -40(%rbp)		# if there was not enough opening brackets before the closing then the parentheses is wrong
			je wrong
			decq -40(%rbp)			# otherwise we decrement the counter

			jmp next


		angleopen:
			pushq	$4				# push the expected type of bracket to be closed next
			incq -48(%rbp)			# if it is a new open bracket then we increment its counter
			jmp next				

		angleclose:
			popq	%r11			# we check which bracket we are expecting to close
			cmpq	$4, %r11		
			jne		wrong			# if it is different then we say it is wrong

			cmpq $0, -48(%rbp)		# if there was not enough opening brackets before the closing then the parentheses is wrong
			je wrong
			decq -48(%rbp)			# otherwise we decrement the counter

			jmp next

		next:
		inc	%r12					# move to the next character
		jmp loop

	# epilogue
	done:
	cmpq $0, -24(%rbp)			# if the counter is greater than 0 then there are some opening brackets left so it is wrong
	jne wrong
	cmpq $0, -32(%rbp)			# if the counter is greater than 0 then there are some opening brackets left so it is wrong
	jne wrong		
	cmpq $0, -40(%rbp)			# if the counter is greater than 0 then there are some opening brackets left so it is wrong
	jne wrong
	cmpq $0, -48(%rbp)			# if the counter is greater than 0 then there are some opening brackets left so it is wrong
	jne wrong

	movq	$valid, %rax		# if we got through all the checking then everything is fine and we can move the answer to rax
	jmp		epi
	
	wrong:
	movq    $invalid, %rax		# if something got us here then it means that the parentheses is invalid

	epi:
	
	leaq	-16(%rbp), %rsp		# clearing the memory for counters
	popq	%r13				# retrieving r13 value
	popq	%r12				# retrieving r13 value
	movq	%rbp, %rsp			# clear local variables from stack
	popq	%rbp				# restore base pointer location 
	ret

main:
	pushq	%rbp 				# push the base pointer (and align the stack)
	movq	%rsp, %rbp			# copy stack pointer value to base pointer

	movq	$MESSAGE, %rdi		# first parameter: address of the message
	call	check_validity		# call check_validity

	movq 	%rax, %rdi			# we move our answer to %rdi to print it
	movq	$0, %rax			# no SSE register will be used
	call 	printf				# printing the answer

	popq	%rbp				# restore base pointer location 
	movq	$0, %rdi			# load program exit code
	call	exit				# exit the program

