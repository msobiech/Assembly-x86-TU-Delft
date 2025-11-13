.text

output: .asciz	"%c\n"
valid: .asciz "valid"
invalid: .asciz "invalid"
open: .asciz "("
closed: .asciz ")"

.include "test.s"

.global main

# *******************************************************************************************
# Subroutine: check_validity                                                                *
# Description: checks the validity of a string of parentheses as defined in Assignment 6.   *
# Parameters:                                                                               *
#   first: the string that should be check_validity                                         *
#   return: the result of the check, either "valid" or "invalid"                            *
# *******************************************************************************************

# < - 60
# > - 62
# ( - 40 
# ) - 41 
# { - 123
# } - 125
# [ - 91
# ] - 93

check_validity:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	# your code goes here
	leaq	(%rdi), %r12
	
	pushq    $0
    pushq    $0
	
	loop:
		movq	$0, %rsi
        movq    $0, %r13
		movb	(%r12), %r13b
		cmpb	$0, %r13b
		je 		done
		
		cmpb	$40, %r13b 
		je	roundopen	
		
		cmpb	 $41, %r13b
		je	roundclose

		roundopen:
		incq -8(%rbp)
		jmp next

		roundclose:
		cmpq $0, -8(%rbp)
		je wrong
        decq -8(%rbp)
		
		next:
		inc	%r12
		jmp loop

	# epilogue

    done:

	cmpq $0, -8(%rbp)
	jne wrong

	movq	$valid, %rax
	jmp     epi
	
	wrong:

	movq    $invalid, %rax

    epi:
	
	movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret

main:
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq	$MESSAGE, %rdi		# first parameter: address of the message
	call	check_validity		# call check_validity

	movq 	%rax, %rdi
	movq	$0, %rax
	call 	printf

	popq	%rbp			# restore base pointer location 
	movq	$0, %rdi		# load program exit code
	call	exit			# exit the program

