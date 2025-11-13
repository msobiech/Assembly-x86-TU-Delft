.global brainfuck

printout: .asciz "Insstruction : %c ||| %d\n"
print: .asciz "%d"

//*******************************************************
//*              Brainfuck subroutine                   *
//*      Interprets brainfuck code (MAX 100k char)      *
//*        Arguments: The brainfuck code in %rdi        *
//*******************************************************


brainfuck:
	pushq %rbp										# Establishing the stackframe
    movq %rsp, %rbp									# Setting rbp to new rbp

    pushq %rbx                                      # saving the calee saved registers
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    pushq $0                                        # 0 for stack alignment

	movq %rdi, %r12									# r12 will hold memory of our current character in the code	

	movq $0, %r14									# r14 will hold how many characters we have in our code

	#***********************************************************
	#* Loop that makes all unusuble characters spaces          *
	#* It makes it easier later to implement the preprocessing *
	#***********************************************************
	whitespace:
		movb    (%r12), %r15b						# Fetch the current character
		incq    %r14
		cmpb	$0, %r15b							# Check for terminating zero
		je		endwhite							# If yes then jump to the end

		cmpb    $62, %r15b							# 62 = > in Ascii
		je nextWhiteSpace

		cmpb    $60, %r15b							# 60 = < in Ascii
		je nextWhiteSpace

		cmpb    $43, %r15b							# 43 = + in Ascii
		je nextWhiteSpace

		cmpb    $45, %r15b							# 45 = - in Ascii
		je nextWhiteSpace

		cmpb    $46, %r15b							# 46 = . in Ascii
		je nextWhiteSpace

		cmpb    $44, %r15b							# 44 = , in Ascii
		je nextWhiteSpace

		cmpb    $91, %r15b							# 91 = [ in Ascii
		je nextWhiteSpace

		cmpb    $93, %r15b							# 93 = ] in Ascii
		je nextWhiteSpace

		movb	$32, (%r12)							# Make every non usable character a space
		nextWhiteSpace:
		incq 	%r12								# Go to the next character
		jmp whitespace								# Loop
	endwhite:

	#**********************************************
	#* In this part we do the first preprocessing *
	#* We compress the operations into chunks     *
	#*            e.g. +++++ = + 5                *
	#* That way our execution phase is faster     *
	#**********************************************

	shl $3, %r14
	/*movq $0, %rax
	movq $print, %rdi
	movq %r14, %rsi
	call printf

	jmp exit*/

	pushq %rdi

	movq $9, %rax 									# preparing for mmap (syscall number 9)
    movq $0, %rdi 									# we don't care where we get memory so why tell the kernel any hints where we want it
    movq %r14, %rsi 							# how much memory (the longest instruction is read, it takes 27bytes and we want to support 100k instruction programs)
    movq $7, %rdx 									# memory should be executable writable and readable
    # FOR SOME REASON WE NEED TO USE R10 INSTEAD OF RCX (FOR KERNEL)
    movq $34, %r10 									# MAP_ANONYMOUS (we need memory not to open a file) | MAP_PRIVATE (we dont share it between processes and docs said we should give exacly one flag about sharing)
    movq $-1, %r8 									# no file => file descriptor will be -1
    movq $0, %r9 									# no file no offset
    syscall
    movq %rax, %rcx 								# save our new pointer to r15

	movq %rcx, %r13

	movq $9, %rax 									# preparing for mmap (syscall number 9)
    movq $0, %rdi 									# we don't care where we get memory so why tell the kernel any hints where we want it
    movq %r14, %rsi 							# how much memory (the longest instruction is read, it takes 27bytes and we want to support 100k instruction programs)
    movq $7, %rdx 									# memory should be executable writable and readable
    # FOR SOME REASON WE NEED TO USE R10 INSTEAD OF RCX (FOR KERNEL)
    movq $34, %r10 									# MAP_ANONYMOUS (we need memory not to open a file) | MAP_PRIVATE (we dont share it between processes and docs said we should give exacly one flag about sharing)
    movq $-1, %r8 									# no file => file descriptor will be -1
    movq $0, %r9 									# no file no offset
    syscall
    movq %rax, %rdx 								# save our new pointer to r15

	movq %r13, %rcx

	popq %rdi

	movq %rdi, %r12									# r12 will hold memory of our current character in the code
    movq $0, %r13									# r13 will hold our current array index at which we write our compressed versions of instructions
	movq $0, %r14									# Counter of our current instructions. How many of the same instructions in a row have seen so far
	
	compresscalc:
		movb    (%r12), %r15b						# Fetch the current character
		cmpb	$0, %r15b							# Check for terminating zero
		je		endcompresscalc						# If yes then jump to the end

		cmpb	$32, %r15b							# If current character is space then go to the next non-space character
		je		skipwhitespace

		jmp endbackwhitespace						# We have to avoid unnecessary one decrement. It is crucial if we were just skipping all spaces
		skipwhitespace:								# Loop that goes to the next character until it encounters a non-space character
			incq %r12								# Go to the next character
			cmpb $32, (%r12)						# Check if the character is space
			je skipwhitespace						# If yes then go to next character
		decq	%r12								# Counter correction (We end the loop when the (%r12) is not a whitespace, but that is the next character to look at so we decrement r12 so it points to the last whitespace)
		endbackwhitespace:	

		cmpb    $62, %r15b							# 62 = > in Ascii
		je preNextCell

		cmpb    $60, %r15b							# 60 = < in Ascii
		je prePreviousCell

		cmpb    $43, %r15b							# 43 = + in Ascii
		je preIncrement

		cmpb    $45, %r15b							# 45 = - in Ascii
		je preDecrement

		cmpb    $46, %r15b							# 46 = . in Ascii
		je preOutput

		cmpb    $44, %r15b							# 44 = , in Ascii
		je preInput

		cmpb    $91, %r15b							# 91 = [ in Ascii
		je preOpenBracket

		cmpb    $93, %r15b							# 93 = ] in Ascii
		je preCloseBracket
		
		jmp nextIterationCompr						# None of the cases means that we go to the next character(It really shouldn't happen but just in case)

		preNextCell:								# Case for >
			incq %r14								# Increment the counter
			movb +1(%r12), %r11b					# Check if the next character is the same ( We look at next and not previous out of convenience)
			cmpb %r11b, %r15b						# Check if the characters are the same
			jne newchar1							# If not then go to new character case ( It means that our current instruction ended and we should set the array cell to it)
			jmp nextIterationCompr					# Otherwise go to next iteration
			newchar1:
				movq %r14, (%rcx, %r13, 8)			# Set current compressed array cell to our counter
				movq $62, (%rdx, %r13, 8)			# Set current intruction array cell to correct instruction code (62 = + in Ascii)
				incq %r13							# Go to next cell
				movq $0, %r14						# Set the counter to 0
				jmp nextIterationCompr				# Go to the next iteration

			
		prePreviousCell:							# Case for <
			decq %r14								# Decrement the counter
			movb +1(%r12), %r11b					# Check if the next character is the same	
			cmpb %r11b, %r15b						# Check if the characters are the same
			jne newchar2							# If not then go to new character case
			jmp nextIterationCompr					# Otherwise go to next iteration
			newchar2:
				movq %r14, (%rcx, %r13, 8)			# Set current compressed array cell to our counter
				movq $62, (%rdx, %r13, 8)			# Set current intruction array cell to correct instruction code (62 = + in Ascii)
				incq %r13							# Go to next cell
				movq $0, %r14						# Set the counter to 0
				jmp nextIterationCompr				# Go to the next iteration
		
		preIncrement:								# Case for +
			incq %r14								# Increment the counter
			movb +1(%r12), %r11b					# Check if the next character is the same	
			cmpb %r11b, %r15b						# Check if the characters are the same
			jne newchar3							# If not then go to new character case
			jmp nextIterationCompr					# Otherwise go to next iteration
			newchar3:
				movq %r14, (%rcx, %r13, 8)			# Set current compressed array cell to our counter
				movq $43, (%rdx, %r13, 8)			# Set current intruction array cell to correct instruction code
				incq %r13							# Go to next cell
				movq $0, %r14						# Set the counter to 0
				jmp nextIterationCompr				# Go to the next iteration

		preDecrement:								# Case for -
			decq %r14								# Decrement the counter
			movb +1(%r12), %r11b					# Check if the next character is the same	
			cmpb %r11b, %r15b						# Check if the characters are the same
			jne newchar4							# If not then go to new character case
			jmp nextIterationCompr					# Otherwise go to next iteration
			newchar4:
				movq %r14, (%rcx, %r13, 8)			# Set current compressed array cell to our counter
				movq $43, (%rdx, %r13, 8)			# Set current intruction array cell to correct instruction code
				incq %r13							# Go to next cell
				movq $0, %r14						# Set the counter to 0
				jmp nextIterationCompr				# Go to the next iteration

		preOutput:									# Case for .
			movq $1, %r14							# Set the counter to 1
			movq %r14, (%rcx, %r13, 8)				# Set current compressed array cell to our counter
			movq $46, (%rdx, %r13, 8)				# Set current intruction array cell to correct instruction code
			incq %r13								# Go to next cell
			movq $0, %r14							# Set the counter to 0
			jmp nextIterationCompr					# Go to the next iteration

		preInput:									# Case for ,
			movq $1, %r14							# Set the counter to 1
			movq %r14, (%rcx, %r13, 8)				# Set current compressed array cell to our counter
			movq $44, (%rdx, %r13, 8)				# Set current intruction array cell to correct instruction code (44 = , in Asciie)
			incq %r13								# Go to next cell
			movq $0, %r14							# Set the counter to 0
			jmp nextIterationCompr					# Go to the next iteration

		preOpenBracket:								# Case for [
			movq $91, (%rdx, %r13, 8)				# Set current intruction array cell to correct instruction code
			incq %r13								# Go to next cell
			movq $0, %r14							# Set the counter to 0
			jmp nextIterationCompr					# Go to the next iteration

		preCloseBracket:
			movq $93, (%rdx, %r13, 8)				# Case for ]
			incq %r13								# Go to next cell
			movq $0, %r14							# Set the counter to 0
			jmp nextIterationCompr					# Jump to next character
			
		nextIterationCompr:
		incq %r12									# Go to the next character
		jmp compresscalc							# Loop
	endcompresscalc:
	movq $0, (%rcx, %r13, 8)						# Add terminating zero to both of the arrays
	movq $0, (%rdx, %r13, 8)

	movq $1, %r12									# r12 will hold our current array index
	movq $0, %r13									# Pointer to overwrite our operations in correct array cell
	
	connectloop:
		movq (%rdx,%r12,8), %r15					# r15 will hold our current instruction code
		movq (%rcx,%r12,8), %r14					# r14 will hold our compressed instruction value
		cmpq $0, %r15								# Check if current instruction is the terminating zero
		je endconnectloop
		
		cmpb    $46, %r15b							# 46 = . in Ascii
		je rewriteconn

		cmpb    $44, %r15b							# 44 = , in Ascii
		je rewriteconn

		cmpb    $91, %r15b							# 91 = [ in Ascii
		je rewriteconn

		cmpb    $93, %r15b							# 93 = ] in Ascii
		je rewriteconn

		movq (%rdx,%r13,8), %r8
		movq (%rcx,%r13,8), %r9
		cmpq %r8, %r15
		jne rewriteconn
		addq %r14,(%rcx,%r13,8)
		jmp nextinterconn
		rewriteconn:
			incq %r13
			movq (%rcx,%r12,8), %rax				# We move our current instruction value into new array cell
			movq %rax, (%rcx,%r13,8)	
			movq (%rdx,%r12,8), %rax				# We move our current instruction id into new array cell
			movq %rax, (%rdx,%r13,8)
		nextinterconn:
		incq %r12
		jmp connectloop

	endconnectloop:
	incq %r13
	movq $0, (%rcx, %r13, 8)						# Add terminating zero to both of the arrays
	movq $0, (%rdx, %r13, 8)

	#***************************************************************
	#* This part detects common occuring patters and changes them  *
	#*                into custom instructions                     *
	#*    e.g. [->>+<<] = M 2 (Addmoving value #> in direction)    *
	#*         [-] = S 0 (Setting current cell to 0)               *
	#***************************************************************

	movq $0, %r12									# r12 will hold our current array index
	movq $0, %r13									# Pointer to overwrite our operations in correct array cell
	//leaq compressed, %rcx							# compressed will hold our compressed instruction value at given index
	//leaq instruction, %rdx							# instruction will hold our type of instruction at given idex
	optimizeloop:
		movq (%rdx,%r12,8), %r15					# r15 will hold our current instruction code
		movq (%rcx,%r12,8), %r14					# r14 will hold our compressed instruction value
		cmpq $0, %r15								# Check if current instruction is the terminating zero
		je endoptimize

		cmpq $91, %r15								# If the current instruction is not [ then go to then rewrite it and go to the next
		jne rewrite									

		movq %r12, %r8								# Backup value of r13 to rollback in case of failure
		incq %r12									# Go to the next instruction
		movq (%rdx,%r12,8), %rax					# Move the next instruction to rax to check if it is '-'
		movq (%rcx,%r12,8), %rbx					# Move the next instruction value to rbx to check if it is exactly 1 '-'


		
		cmpq $43, %rax								# if it isn't minus then we rollback
		jne rollback
		cmpq $-1, %rbx								# if it isn't exactly 1 minus then we rollback
		jne rollback
		
		incq %r12									# Go to the next character
		movq (%rdx,%r12,8), %rax					# Instruction after the - ( [-X+>>] )
		movq (%rcx,%r12,8), %rbx					# Value of the instruction after the -

		cmpq $93, %rax								# Check if the next instruction is ] (The [-] case)
		jne nextif									# If not we still check for the moveadd value case

		movq $0, (%rcx,%r13,8)						# Set it to instruction value 0
		movq $83, (%rdx,%r13,8)						# Set it to S as instruction id
		jmp nextIterationOpt						# If everything went through we go to next instruction

		nextif:
		addq $2, %r12
		movq (%rdx,%r12,8), %r9						# Instruction after the + ( [-<<+X] )
		movq (%rcx,%r12,8), %r10					# Value of the instruction after the +
		
		cmpq $62, %rax								# Check if they are move instructions
		jne rollback
		cmpq %rax, %r9
		jne rollback
		
		addq %rbx, %r10								# Check if one operation is exactly the opposite of the other one (So the amount of < is the same as >)
		jnz rollback
		
		decq %r12									# Go back one operation so ( [-<<X>>] )
		movq (%rdx,%r12,8), %r9						# Check for the plus
		movq (%rcx,%r12,8), %r10					
		cmpq $43, %r9								# If it isn't plus we rollback		
		jne rollback
		cmpq $1, %r10								# if it isn't exactly 1 plus then we rollback
		jne rollback
		
		addq $2, %r12								# Go to the instruction that should be ] ( [->>+<<X ) 
		movq (%rdx,%r12,8), %r9						# Check for the ']'
		cmpq $93, %r9								# If it isn't ] we rollback
		jne rollback
	
		movq %rbx, (%rcx,%r13,8)					# Move the value of the first moves so ( [-X+<<] ) as instruction value
		movq $77, (%rdx,%r13,8)						# Set the instruction id to M in ascii
		jmp nextIterationOpt
		rollback:									# Rolling back means going back to the state before the checking
			movq %r8, %r12							# We move our saved backup of instruction pointer into instruction pointer
		rewrite:
			movq (%rcx,%r12,8), %rax				# We move our current instruction value into new array cell
			movq %rax, (%rcx,%r13,8)	
			movq (%rdx,%r12,8), %rax				# We move our current instruction id into new array cell
			movq %rax, (%rdx,%r13,8)

		nextIterationOpt:
		incq %r13									# Go to the next cell that we write in
		incq %r12									# Go to the next instruciton that we look at
		jmp optimizeloop

	endoptimize:
	movq $0, (%rcx, %r13, 8)						# Set new terminating zero at the end of both arrays
	movq $0, (%rdx, %r13, 8)
	
	movq $0, %r13 			   						# Current cell that we look at (pointer)
	leaq array, %r14		   						# r14 will hold our array address

	zeroloop: 										# Loop that initialises everything to zero
		cmpq  $30000, %r13 
		je endloop				 					# Check if it is our last address
		movq $0, (%r14, %r13, 1) 					# Set current cell to 0
		addq $4, %r13		     					# Go to the next cell
		jmp zeroloop			 					# Jump to the loop
	endloop:

	
	// +++++++++++++++++++++++++++++++++++++
	// +++++++++++++++++++++++++++++++++++++
	// +++++++++++++++++++++++++++++++++++++
	// +++++++++++++++++++++++++++++++++++++
	// +++++++++++++++++++++++++++++++++++++

	movq $1, %r13
	movq $0, %r12
	calcbytes:
		movb (%rdx, %r12, 8), %al 					# load the instruction id to al for processing
		cmpb $0, %al 								# terminating zero -> quit loop
		je bytesend

		cmpb $43, %al 								# + (ascii 43) (all minusses got changed to plusses with negative values earlier)
		je bplus

		cmpb $62, %al 								# > (ascii 63) (all < got changed to > with negative values earlier)
		je bright
		
		cmpb $46, %al 								# . (ascii 46)
		je bwrite
		
		cmpb $44, %al 								# , (ascii 44)
		je bread
		
		cmpb $91, %al								# [ (ascii 91)
		je bZjmp
		
		cmpb $93, %al 								# ] (ascii 93)
		je bNZjmp

		cmpb $77, %al 								# M (ascii 77)
		je bmove
	
		cmpb $83, %al 								# S (ascii 83)
		je bzero

		bplus:
			addq $3 , %r13
			jmp bnext
		bright:
			addq $6 , %r13
			jmp bnext
		bwrite:
			addq $9 , %r13
			jmp bnext
		bread:
			addq $27 , %r13
			jmp bnext
		bZjmp:
			addq $9 , %r13
			jmp bnext
		bNZjmp:
			addq $9 , %r13
			jmp bnext
		bmove:
			addq $11 , %r13
			jmp bnext
		bzero:
			addq $3 , %r13
		bnext:
			incq %r12
			jmp calcbytes
	bytesend:

	movq %rdx, %r14
	movq %rcx, %r12

	movq $9, %rax 									# preparing for mmap (syscall number 9)
    movq $0, %rdi 									# we don't care where we get memory so why tell the kernel any hints where we want it
    movq %r13, %rsi 							# how much memory (the longest instruction is read, it takes 27bytes and we want to support 100k instruction programs)
    movq $7, %rdx 									# memory should be executable writable and readable
    # FOR SOME REASON WE NEED TO USE R10 INSTEAD OF RCX (FOR KERNEL)
    movq $34, %r10 									# MAP_ANONYMOUS (we need memory not to open a file) | MAP_PRIVATE (we dont share it between processes and docs said we should give exacly one flag about sharing)
    movq $-1, %r8 									# no file => file descriptor will be -1
    movq $0, %r9 									# no file no offset
    syscall
    movq %rax, %r15 								# save our new pointer to r15

	movq %r12, %rcx
	movq %r14, %rdx

	/*
	*  In the following chunk of code we will be outputting the bytes of the x86-64 instructions that correspond with our BF program (to later execute the whole thing)
	*  We will be doing that by having the address of the next free byte in the reserved array of executable memory in r14 and moving values there with indirect addressing
	*  After each mov r14 needs to be adjusted to keep it pointing at the next free space, we can do that by adding the number of bytes we mov'ed
	*  Moving a longer-than-one-byte value uses the byte at r14 and the bytes at bigger indexes so we don't have to worry about overwritting already good data (we just need to rememer to add the correct number to r14)
	*  x86-64 is little endian so we need to swap the order of bytes each multi-byte mov so the correctly settle in the memory
	*  We can mov a 3 byte value by mov'ing a doubleword (int in C) where the first byte dosen't matter and adding 3 to r14 (the first byte of the value will be the last in memory and as we added only 3 to r14 it will be pointing to this byte, essentially indicating it as unused space)
	*  There is no mov instruction with 8-byte immediete value and memory operands so everything needs to be split into 4-byte chunks
	*  There is no mov instruction with two memory operands so some operations will have to be done in two movs
	*/

	/*
	*  In the BF run we will be using rbx as the BF pointer and r12 as the a pointer to the next free byte in the output buffer (we will set those registers to the correct later)
	*  A nice shortcut in getting the machine code is to create a test program with the instructions you want and assemble and disassemble it ("as test.s && objdump -d")
	*  When you use the method above it's still important to know where should you put the immediete values 
	*  AMD Programmer Manual Volume 3 is useful
	*/

	
		

	# r8 the instruction array address
	# r9 the compressed array address
	# r12 current index of copmiled instruction
	# r14 address of next execmem write
	# r15 beggining of exec memory

	movq %rcx, %r9
	movq %rdx, %r8
	movq $0, %r12
	movq %r15, %r14
	movq $0, %rax

	cmloop:
		movb %al, %sil
		movb (%r8, %r12, 8), %al 					# load the instruction id to al for processing

		cmpb $0, %al 								# terminating zero -> quit loop
		je cmlend

		cmpb $43, %al 								# + (ascii 43) (all minusses got changed to plusses with negative values earlier)
		je cmplus

		cmpb $62, %al 								# > (ascii 63) (all < got changed to > with negative values earlier)
		je cmright
		
		cmpb $46, %al 								# . (ascii 46)
		je cmwrite
		
		cmpb $44, %al 								# , (ascii 44)
		je cmread
		
		cmpb $91, %al								# [ (ascii 91)
		je cmZjmp
		
		cmpb $93, %al 								# ] (ascii 93)
		je cmNZjmp

		cmpb $77, %al 								# M (ascii 77)
		je cmmove
	
		cmpb $83, %al 								# S (ascii 83)
		je cmzero

		cmplus:
			/*
			*  80 03 **             	addb   $0x**,(%rbx)	# just adding the requested cale to the cell pointed to by the bf pointer (we only care about the last byte because bf cells loop from 255 to 0)
			*/
			movw $0x0380, (%r14)
			addq $2, %r14
			movb (%r9, %r12, 8), %al				# current "compressed" array entry (will be used as immiediete value) (moving to al as there is no mem -> mem mov)
			movb %al, (%r14)
			addq $1, %r14
			incq %r12 								# next loop iteration
			jmp cmloop
			
		cmright:
			/*
			*  81 c3 ** ** ** **    	add    $0x********,%ebx	# just adding the requested offset to th bf pointer
			*/
			movw $0xc381, (%r14)
			addq $2, %r14
			movl (%r9, %r12, 8), %eax				# current "compressed" array entry (will be used as immiediete value) (moving to eax as there is no mem -> mem mov)
			movl %eax, (%r14)
			addq $4, %r14
			incq %r12 								# next loop iteration
			jmp cmloop

		
		/*cmwrite: # syscall every print
			/*
			*  48 c7 c0 01 00 00 00 	mov    $0x1,%rax	# write syscal numer = 1
       		*  48 c7 c7 01 00 00 00 	mov    $0x1,%rdi	# 
       		*  48 89 de             	mov    %rbx,%rsi	# 
      		*  48 c7 c2 01 00 00 00 	mov    $0x1,%rdx	# we want to write 1 byte
      		*  0f 05                	syscall
			*//*
			movl $0x01c0c748, (%r14)
			addq $4, %r14
			movl $0x48000000, (%r14)
			addq $4, %r14
			movl $0x0001c7c7, (%r14)
			addq $4, %r14
			movl $0x89480000, (%r14)
			addq $4, %r14
			movl $0xc2c748de, (%r14)
			addq $4, %r14
			movl $0x00000001, (%r14)
			addq $4, %r14
			movw $0x050f, (%r14)
			addq $2, %r14
			incq %r12 								# next loop iteration
			jmp cmloop*/
		
		cmwrite: # with output buffering
			/*
			*  8a 03                	mov    (%rbx),%al	# temparaily move the cell pointed to bf pointer to al (there is non mov from emmory to memory)
       		*  41 88 04 24          	mov    %al,(%r12)	# the second part of the memory to memory mov
       		*  49 ff c4             	inc    %r12			# we used one space, the next free space moves
			*/
			movl $0x8841038a, (%r14)
			addq $4, %r14
			movl $0xff492404, (%r14)
			addq $4, %r14
			movb $0xc4, (%r14)
			addq $1, %r14
			incq %r12 								# next loop iteration
			jmp cmloop

		cmread:
			/*
			*  48 31 c0             	xor    %rax,%rax	# set rax to 0 (read syscall number)
       		*  48 31 ff             	xor    %rdi,%rdi	# set rdi to 0 (stdin)
       		*  48 89 de             	mov    %rbx,%rsi	# set the pointer to read to to the bf pointer (we want to read to the curent cell)
       		*  48 c7 c2 01 00 00 00 	mov    $0x1,%rdx	# set rdx to 1 (the number of chars to read)
      		*  0f 05                	syscall
      		*  48 83 f8 00          	cmp    $0x0,%rax	# if the read syscall returns 0 we reached end of file and therefore should set 0 in the cell
      		*  75 03                	jne    03 <label>	# if we didn't reach EOF skip the setting of 0
      		*  c6 03 00             	movb   $0x0,(%rbx)	# move the 0 to the place we read to
			*  <label>:										# because jumps are relative we can just use the hardcoded value
			*/
			movl $0x48c03148, (%r14)
			addq $4, %r14
			movl $0x8948ff31, (%r14)
			addq $4, %r14
			movl $0xc2c748de, (%r14)
			addq $4, %r14
			movl $0x00000001, (%r14)
			addq $4, %r14
			movw $0x050f, (%r14)
			addq $2, %r14
			movl $0x00f88348, (%r14)
			addq $4, %r14
			movl $0x03c60375, (%r14)
			addq $4, %r14
			movb $0x00, (%r14)
			addq $1, %r14
			incq %r12 								# next loop iteration
			jmp cmloop

		cmZjmp:
			/*
			*  80 3b 00             	cmpb   $0x0,(%rbx)		# we need to make sure the rflags are set correctly
       		*  0f 84 ** ** ** **    	je     0x********	# we use the opcode that goes with a 4 byte offset in case we will need the whole 4 bytes
	   		*/
			movl $0x00003b80, (%r14)
			addq $3, %r14 							# one byte of the int above gets ignored and will be overwritten with next mov as we add 3 not 4, it's easier to ignore one byte than doing movw + movb
			movw $0x840f, (%r14)
			addq $2, %r14
			pushq %r14								# pushing the address of the jump offset number as we don't know where the matching ] is yet (we will update the value here in ] logic)
			addq $4, %r14							# we increment r14 but don't put anything here as stated above (we just reserve the space for the offset)
			incq %r12 								# next loop iteration
			jmp cmloop

		cmNZjmp:
			/*
			*  80 3b 00             	cmpb   $0x0,(%rbx)		# we need to make sure the rflags are set correctly
       		*  0f 85 ** ** ** **    	jne     0x********	# we use the opcode that goes with a 4 byte offset in case we will need the whole 4 bytes
	   		*/
			movl $0x00003b80, (%r14)
			addq $3, %r14							# one byte of the int above gets ignored and will be overwritten with next mov as we add 3 not 4, it's easier to ignore one byte than doing movw + movb
			movw $0x850f, (%r14)
			addq $2, %r14
			popq %rax								# we pop the address of the corresponding ]'s jump offset (now r14 is the ] and rax is the [ offset address)
			movq %rax, %rsi							# we copy the ] offset address to rsi, we need it for calculations and unchanged to be able to put the correct value there
			subq %r14, %rax							# the jump offset is how far those addresses are apart (we subtract the bigger from the smaller so the resulting number will be negative, so it can be used as the "jump back" offset)
			movl %eax, (%r14)						# we update the offset of the ]'s jump
			addq $4, %r14							# usual add, we used 4 bytes so the next free space is 4 bytes further in the array
			negl %eax								# for jumping in the other direction we negate the jump amount (now it will "jump forward")
			movl %eax, (%rsi)						# set the ['s offset to the calculated one using the unchanged address we copied to rsi 5 lines earlier
			incq %r12 								# next loop iteration
			jmp cmloop

		cmmove:
			/*
			*  8a 03                	mov    (%rbx),%al			# temprarily moving the cell bf pointer points to (there is no memory to memory add)
       		*  00 83 ** ** ** **    	add    %al,0x********(%rbx)	# adding the moved cell to the target with specified offset
       		*  c6 03 00             	movb   $0x0,(%rbx)			# setting the current cell to 0 (it got moved so it's no longer here)
			*/
			movl $0x8300038a, (%r14)
			addq $4, %r14
			movl (%r9, %r12, 8), %eax				# current "compressed" array entry (will be used as immiediete value) (moving to eax as there is no mem -> mem mov)
			movl %eax, (%r14)
			addq $4, %r14
			movl $0x000003c6, (%r14)
			addq $3, %r14
			incq %r12 								# next loop iteration
			jmp cmloop

		cmzero:
			/*
			*  c6 03 00             	movb   $0x0,(%rbx)	# just setting 0 to the current cell
			*/
			movl $0x000003c6, (%r14)
			addq $3, %r14
			incq %r12 								# next loop iteration
			jmp cmloop
	cmlend:

	movb $0xc3, (%r14)								# adding the "ret" opcode to the end so that we can do some stuff after the BF program terminates (it will return to out function)

	leaq array, %rbx 								# preparing the registers according to what was stated earlier
	leaq outbuffer, %r12

	call *%r15 										# actually executing the machine code corresponding to the BF program

	leaq outbuffer, %r13
	subq %r13, %r12 								# calculating how many characters we need to print (subracting the address of the next free one and the array beggining)

	cmpq $0, %r12
	je nooutput 									# if we need to print 0 characters we just skip the printing
	movq $1 , %rax   								# Syscall for write
	movq $1	, %rdi	    							# File descriptor (stdout)
	leaq outbuffer, %rsi 							# the output buffer address
	movq %r12, %rdx 								# the calculated amount of chars
	syscall											# write
	nooutput:

	exit:
    popq %r15                                       # fisrt thing is the alignment 0
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    movq $0, %rax              						# Set return value to 0
    movq %rbp, %rsp            						# Restore the stack pointer
    popq %rbp                  						# Restore the base pointer
    ret

.section	.bss

array: .space 32768									# Array with our cells for brainfuck
outbuffer: .space 2147483648							# Array for output buffering
