

.global brainfuck

format_str: .asciz "We should be executing the following code:\n%s\n"
number: .asciz "%d\n"


preinstruction: .asciz "Before the instruction : %d\n"
instruction: .asciz "Current instruction is : %c\n"
iterator: .asciz "Current iterator is : %d\n"
conditional: .asciz "Conditional: %d\n"
postinstruction: .asciz "After the instruction : %d\n"


brainfuck:
    pushq %rbp
    movq %rsp, %rbp
    
	movq %rdi, %r12			   # String to go through
	movq $0, %r13 			   # Current cell that we look at (pointer)
	leaq lookup(%rip), %r14		   # r14 will hold our array address
	lookupcalc:
		movb    (%r12), %r15b
		cmpb	$0, %r15b
		je		endlookupcalc

		cmpb    $91, %r15b
		je newcorresponding

		cmpb    $93, %r15b
		je writecorresponding

		movq $0, (%r14, %r13, 8)
		jmp nextit
		newcorresponding:
			leaq (%r14, %r13, 8), %r11
			pushq %r11
			pushq %r12
			jmp nextit
		writecorresponding:
			popq %r11
			popq %r10
			movq %r12, (%r10)
			movq %r11, (%r14, %r13, 8)
			jmp nextit
		
		nextit:
		
		incq %r13
		incq %r12
		jmp lookupcalc
	endlookupcalc:

	movq $0, %r13 			   # Current cell that we look at (pointer)
	leaq array(%rip), %r14		   # r14 will hold our array address

	zeroloop: # Loop that initialises everything to zero
		cmpq  $30000, %r13 
		je endloop				 # Check if it is our last address
		movq $0, (%r14, %r13, 1) # Set current cell to 0
		addq $4, %r13		     # Go to the next cell
		jmp zeroloop			 # Jump to the loop
	endloop:

	movq $0, %r13 			   # Set our current cell to 0
	movq %rdi, %r12			   # Move the brainfuck code to r12 (r12 will be our instruction pointer)
	movq %r12, %rcx	

	mainloop:
		

		
		movb    (%r12), %r15b
		cmpb	$0, %r15b
		je		next
		cmpb    $62, %r15b
		je nextCell

		cmpb    $60, %r15b
		je previousCell

		cmpb    $43, %r15b
		je increment

		cmpb    $45, %r15b
		je decrement

		cmpb    $46, %r15b
		je output

		cmpb    $44, %r15b
		je input

		cmpb    $91, %r15b
		je openbracket

		cmpb    $93, %r15b
		je closebracket
		
		jmp nextIteration
		nextCell:
			incq    %r13
			jmp nextIteration

		previousCell:
			decq	%r13
			jmp nextIteration

		increment:
			incb (%r14, %r13, 1)
			jmp nextIteration

		decrement:
			decb (%r14, %r13, 1)
			jmp nextIteration

		input:
			

			pushq %rcx

			movq $instruction, %rdi
			movzb %r15b, %rsi
			movq $0, %rax
			call printf

			movq $0 , %rax   	#syscall for read
			movq $0, %rdi	    
			leaq (%r14, %r13, 1), %rsi
			movq $1, %rdx

			syscall
			popq %rcx
			jmp nextIteration
		output:

			pushq %rcx
		
			movq $1 , %rax   	#syscall for write
			movq $1	, %rdi	    
			leaq (%r14, %r13, 1), %rsi
			movq $1, %rdx
			syscall

			popq %rcx

			jmp nextIteration

		openbracket:
			movzb (%r14, %r13, 1), %r10
			cmpq $0, %r10
			jne nextIteration

			movq %r12, %r11
			subq %rcx, %r11
			leaq lookup(%rip), %r10

			movq (%r10, %r11, 8), %r12

			jmp nextIteration
				

		closebracket:
			movzb (%r14, %r13, 1), %r10
			cmpq $0, %r10
			je nextIteration
			
			movq %r12, %r11

			

			subq %rcx, %r11
			leaq lookup(%rip), %r10
			movq (%r10, %r11, 8), %r12
 
			jmp nextIteration
		

		nextIteration:

		incq	%r12
		jmp mainloop
	next:


	exit:
    movq $0, %rax              # Set return value to 0
    movq %rbp, %rsp            # Restore the stack pointer
    popq %rbp                  # Restore the base pointer
    ret

.section	.data

array: .space 30007
lookup: .space 800008