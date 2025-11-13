.global sha1_chunk

sha1_chunk:
	pushq 	%rbp
	movq	%rsp, %rbp
	
	pushq   %r12				# saving register values to retrieve them later
	pushq   %r13
	pushq   %r14
	pushq	%r15

	# r10 - r14 will be a - e from pseudocode
	movl   (%rdi), %r10d
	movl   +4(%rdi), %r11d
	movl   +8(%rdi), %r12d
	movl   +12(%rdi), %r13d
	movl   +16(%rdi), %r14d
	
	movq 	$16, %r15
	
	extendloop:					# r15 = i
		

		movq	%r15, %r8		# r8 = i-3
		subq	$3, %r8			#
		
		movl	(%rsi,%r8,4), %r9d # r9 = w[i-3] 

		subq	$5, %r8				# r8 = i-8
		xorl	(%rsi,%r8,4), %r9d	# r9 = w[i-3] XOR w[i-8]

		subq	$6, %r8				# r8 = i-14
		xorl	(%rsi,%r8,4), %r9d	# r9 = w[i-3] XOR w[i-8] XOR w[i-14]

		subq	$2, %r8				# r8 = i-16
		xorl	(%rsi,%r8,4), %r9d	# r9 = w[i-3] XOR w[i-8] XOR w[i-14] XOR w[i-16]

		roll	$1, %r9d			# r9 = (w[i-3] XOR w[i-8] XOR w[i-14] XOR w[i-16]) leftrotate 1
		movl	%r9d, (%rsi,%r15,4) # w[i] = (w[i-3] XOR w[i-8] XOR w[i-14] XOR w[i-16]) leftrotate 1


		incq	%r15
		cmpq	$79, %r15		#if i<=79 jump
		jle		extendloop
	
	
	movq	$0, %r15
	mainloop:
		
		cmpq	$19, %r15
		jle		caseless19

		cmpq	$39, %r15
		jle		caseless39

		cmpq	$59, %r15
		jle		caseless59

		cmpq	$79, %r15
		jle		caseless79
		caseless19:
			movl $0x5A827999, %r9d	# k = $0x5A827999
			movl %r11d, %eax		# eax = b
			andl %r12d, %eax 		# eax = b AND c

			movl %eax, %r8d			# f = b AND c

			movl %r11d, %eax		# eax = b
			notl %eax 				# eax = NOT b
			andl %r13d, %eax		# eax = (NOT b) AND d

			orl %eax, %r8d			# f = (b AND c) OR ((NOT b) AND d)

			jmp end
		
		caseless39:
			movl $0x6ED9EBA1, %r9d	# k = $0x6ED9EBA1
			movl %r11d, %r8d		# f = b
			xorl %r12d, %r8d		# f = b XOR c
			xorl %r13d, %r8d		# f = b XOR c XOR d

			jmp end
			
		caseless59:
			movl $0x8F1BBCDC, %r9d	# k = $0x8F1BBCDC
			movl %r11d, %eax		# eax = b
			andl %r12d, %eax 		# eax = b AND c
			movl %eax, %r8d			# f = b AND c

			movl %r11d, %eax		# eax = b
			andl %r13d, %eax 		# eax = b AND d
			orl %eax, %r8d			# f = (b AND c) OR (b AND d)

			movl %r12d, %eax		# eax = c
			andl %r13d, %eax 		# eax = c AND d
			orl %eax, %r8d			# f = (b AND c) OR (b AND d) OR (c AND d)
			jmp end

		caseless79:
			movl $0xCA62C1D6, %r9d	# k = $0xCA62C1D6
			movl %r11d, %r8d		# f = b
			xorl %r12d, %r8d		# f = b XOR c
			xorl %r13d, %r8d		# f = b XOR c XOR d

			jmp end

		end:
		
		pushq	%r10				 # temp will be on stack. temp = a
		roll	$5, (%rsp)			 # temp = (a leftrotate 5)
		addl	%r8d, (%rsp)		 # temp = (a leftrotate 5) + f
		addl	%r14d, (%rsp)		 # temp = (a leftrotate 5) + f + e
		addl	%r9d, (%rsp) 		 # temp = (a leftrotate 5) + f + e + k
		#addl	(%rsi,%r8,4), (%rsp) # temp = (a leftrotate 5) + f + e + k + w[i]

		movl	%r13d, %r14d		 # e = d
		movl	%r12d, %r13d		 # d = c
		roll	$30, %r11d			 # b = b leftrotate 30
		movl	%r11d, %r12d		 # c = b leftrotate 30
		movl 	%r10d, %r11d		 # b = a
		popq	%r10
		addl	(%rsi,%r15,4), %r10d # temp = (a leftrotate 5) + f + e + k + w[i]

		incq	%r15
		cmpq	$79, %r15
		jle		mainloop
	
	addl   %r10d, (%rdi)	# h0 + a
	addl   %r11d, +4(%rdi)	# h2 + b
	addl   %r12d, +8(%rdi)	# h2 + c
	addl   %r13d, +12(%rdi)	# h3 + d
	addl   %r14d, +16(%rdi) # h4 + e

	popq	%r15	#retrieving the registers
	popq 	%r14
	popq 	%r13
	popq 	%r12

	movq	%rbp, %rsp
	popq	%rbp
	ret
