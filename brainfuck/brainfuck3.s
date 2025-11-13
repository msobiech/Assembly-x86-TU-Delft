.global brainfuck

printout: .asciz "Insstruction : %c ||| %d\n"

brainfuck:
    pushq %rbp										# Establishing the stackframe
    movq %rsp, %rbp									# Setting rbp to new rbp
    
	movq %rdi, %r12			   						# r12 will hold our memory address of currently checked char
	movq $0, %r13 			   						# Current cell that we look at (pointer)
	leaq lookup, %r14		   						# r14 will hold our array address
	lookupcalc:	
		movb    (%r12), %r15b						# Moving our current character to r15	
		cmpb	$0, %r15b							# Check if it is a terminating zero
		je		endlookupcalc						# If it is then end the calculations

		cmpb    $91, %r15b							# 91 = [ in ascii
		je newcorresponding						

		cmpb    $93, %r15b							# 93 = ] in ascii
		je writecorresponding

		movq $0, (%r14, %r13, 8)					# If none of them are correct then we go to the next 
		jmp nextit									# Jump to next iteration
		newcorresponding:
			leaq (%r14, %r13, 8), %r11				# Load the address of the array cell to r11 for later push
			pushq %r11								# Push the current array cell to stack
			pushq %r12								# Push current memory address of our character to stack
			jmp nextit								# Jump to next character
		writecorresponding:
			popq %r11								# Retrieve the corresponding bracket memory address in the code
			popq %r10								# Retrieve the corresponding array cell to write in it
			movq %r12, (%r10)						# Set the opening bracket array cell to my memory address 
			movq %r11, (%r14, %r13, 8)				# Set the corresponding opening bracket memory address in my array cell
			jmp nextit								# Jump to next character
		nextit:
		incq %r13									# Increase r13 for it to point to the next cell in the array
		incq %r12									# Increase r12 for it to point to the next character in the code
		jmp lookupcalc								# Go to the next iteration of the loop
	endlookupcalc:

	movq $0, %r13 			   						# Current cell that we look at (pointer)
	leaq array, %r14		   						# r14 will hold our array address

	zeroloop: 										# Loop that initialises everything to zero
		cmpq  $30000, %r13 
		je endloop				 					# Check if it is our last address
		movq $0, (%r14, %r13, 1) 					# Set current cell to 0
		addq $4, %r13		     					# Go to the next cell
		jmp zeroloop			 					# Jump to the loop
	endloop:

	movq $0, %r13 			   						# We start at cell 0
	movq %rdi, %r12			   						# Move the brainfuck code to r12 (r12 will be our instruction pointer)
	movq %rdi, %rcx									# We will need the starting address to later calculate which char are we on currently

	mainloop:
		movb    (%r12), %r15b						# Fetch the current character
		cmpb	$0, %r15b							# Check for terminating zero
		je		exit								# If yes then jump to the end
		cmpb    $62, %r15b							# 62 = > in Ascii
		je nextCell

		cmpb    $60, %r15b							# 60 = < in Ascii
		je previousCell

		cmpb    $43, %r15b							# 43 = + in Ascii
		je increment

		cmpb    $45, %r15b							# 45 = - in Ascii
		je decrement

		cmpb    $46, %r15b							# 46 = . in Ascii
		je output

		cmpb    $44, %r15b							# 44 = , in Ascii
		je input

		cmpb    $91, %r15b							# 91 = [ in Ascii
		je openbracket

		cmpb    $93, %r15b							# 93 = ] in Ascii
		je closebracket
		
		jmp nextIteration							# If none of the above then jump to the next iteration
		nextCell:									# Case for >
			incq    %r13							# Go to the next cell
			jmp nextIteration						# Go to the next iteration

		previousCell:								# Case for <
			decq	%r13							# Go to the previous cell
			jmp nextIteration						# Go to the next iteration

		increment:
			incb (%r14, %r13, 1)					# Increment our current array cell
			jmp nextIteration						# Go to the next iteration

		decrement:
			decb (%r14, %r13, 1)					# Decrement our current array cell
			jmp nextIteration						# Go to the next iteration

		input:

			movq %rcx, %r15							# rcx is not callee-saved

			movq $0 , %rax   						# Syscall for read
			movq $0, %rdi	    					# File descriptor (stdin)
			leaq (%r14, %r13, 1), %rsi				# We will write at our current cell
			movq $1, %rdx							# We will read 1 byte

			syscall									# Call the read syscall 

			movq %r15, %rcx							# Retrieve rcx 

			jmp nextIteration						# Go to the next iteration

		output:

			movq %rcx, %r15							# rcx is not callee-saved
		
			movq $1 , %rax   						# Syscall for write
			movq $1	, %rdi	    					# File descriptor (stdout)
			leaq (%r14, %r13, 1), %rsi				# We will read from our current cell
			movq $1, %rdx							# We will write 1 byte
			syscall									# Call the write syscall 

			movq %r15, %rcx							# Retrieve rcx 

			jmp nextIteration						# Go to the next iteration

		openbracket:
			movsx (%r14, %r13, 1), %r10				# Move current cell value to r10
			cmpq $0, %r10							# Check if the value is 0
			jne nextIteration						# If it is not 0 then go to the next iteration

													# Otherwise we have to jump to correct memory location
			movq %r12, %r11							# r11 = Our current memory address
			subq %rcx, %r11							# r11 = current memory address - memory address of the start of the string = current char number
			leaq lookup, %r10						# Load the lookup array address to r10

			movq (%r10, %r11, 8), %r12				# Move the r12 so our current character pointer to the corresponding bracket

			jmp nextIteration						# Go to the next iteration

		closebracket:
			movsx (%r14, %r13, 1), %r10				# Move current cell value to r10
			cmpq $0, %r10							# Check if the value is 0
			je nextIteration						# If it is not 0 then go to the next iteration

													# Otherwise we have to jump to correct memory location
			movq %r12, %r11							# r11 = Our current memory address
			subq %rcx, %r11							# r11 = current memory address - memory address of the start of the string = current char number
			leaq lookup, %r10						# Load the lookup array address to r10

			movq (%r10, %r11, 8), %r12				# Move the r12 so our current character pointer to the corresponding bracket
 
			jmp nextIteration						# Go to the next iteration

		nextIteration:

		incq	%r12								# Go to the next character
		jmp mainloop								# Loop
	exit:
    movq $0, %rax              						# Set return value to 0
    movq %rbp, %rsp            						# Restore the stack pointer
    popq %rbp                  						# Restore the base pointer
    ret

.section	.data

array: .space 30007									# Array with our cells for brainfuck
lookup: .space 800008								# Array with memory jump addresses
