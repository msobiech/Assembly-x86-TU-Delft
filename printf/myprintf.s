.text

hello:
    .asciz "My name is %s. And the number is %u the signed number is %d and what does %% do"

name:
    .asciz "Max"

unsignedintprint:
    .asciz "<uint>"

nullterstringprint:
    .asciz "<string>"

signedintprint:
    .asciz "<int>"




.global main

# ************************************************************
#  Subroutine: printstring                                   *
#  Description : prints string passed in the first parameter *
#  Parameters:                                               * 
#       first: the string that should be printed             *
# ************************************************************
printstring:
    pushq   %rbp                # save the old rbp
    movq    %rsp, %rbp          # set rbp to new rbp

    pushq   %r12                # save values of r12 and r13 to retrieve them later
    pushq   %r13
    
    movq    %rdi, %r13          # copy the address of our string to r13
    printloopstr:
        movb    (%r13), %r12b   # copy the first character to print to r12
        cmpb    $0, %r12b       # check if the character is not terminating the string
        je     donestr          # if it is then jump to the end of printing

        movq    $1, %rax        # system call 1 is sys-write
        movq    $1, %rdi        # 1 is stdout
        movq    %r13, %rsi      # r13 holds our address of the to-be-printed character
        movq    $1, %rdx        # we will only write one character at a time
        syscall             

        incq    %r13            # we move to the next character
        jmp printloopstr        
    donestr:

    popq    %r13                # we retrieve our values of r12 and r13 from the stack
    popq    %r12

    movq    %rbp, %rsp          # clear the memory
    popq    %rbp                # get our old rbp back
    ret 

# ************************************************************
#  Subroutine: printuint                                     *
#  Description : prints unsigned int passed in the first     *
#                parameter                                   *
#  Parameters:                                               * 
#       first: the string that should be printed             *
# ************************************************************
printuint:
    pushq   %rbp                # save the old rbp
    movq    %rsp, %rbp          # set rbp to new rbp

    pushq   %r12                # save values of r12 and r13 to retrieve them later
    pushq   %r13
    pushq   $0
    pushq   $0                  # push the terminating 0 onto the stack
    movq    %rdi, %rax          # copy our to-be-printed value to rax because with division it will be more convenient

    cmpq    $0, %rdi            # if the value would be zero then the loop for pushing onto the stack doesnt work so we have to check it seperately
    je      isZero              
    jmp     pushstack
    isZero:
    pushq   $48                 # if zero then we push onto the stack the '0' manualy

    pushstack:
        cmpq    $0, %rax        # if the current value is 0 then we finished the division
        je  donepush
        
        movq    $10, %r12       # we will divide by 10 but div has to use registers to divide so we move it into r12
        movq    $0, %rdx        # we have to clear the rdx for the division (it will store our remainder)
        div     %r12            # we divide the rax by 10

        addq    $48, %rdx       # convert our remainder to char
        pushq   %rdx            # push it onto the stack
        jmp pushstack           
    donepush:
    
    printloopuint:
        cmpq    $0, (%rsp)      # check if the current top value on stack is the terminating zero
        je  doneuint

        movq    $1, %rax        # system call 1 is sys-write
        movq    $1, %rdi        # 1 is stdout
        leaq    (%rsp), %rsi    # rsp holds our address of the to-be-printed character
        movq    $1, %rdx        # we will only write one character at a time
        syscall

        popq    %r12            # we pop it to r12(doesnt matter where) so we can go to the next character
        jmp printloopuint       

    doneuint:

    movq    %rbp, %rsp
    subq    $16, %rsp

    popq    %r13                # we retrieve our values of r13 and r12
    popq    %r12

    movq    %rbp, %rsp          # clear the memory
    popq    %rbp                # get our old rbp back
    ret 

printint:
    pushq   %rbp                # save the old rbp
    movq    %rsp, %rbp          # set rbp to new rbp

    pushq   %r12                # save values of r12 and r13 to retrieve them later
    pushq   $0

    cmpq    $0, %rdi            # we check if rdi is negative
    jl      negative
    positive:                   # if not. So positive
        call printuint          # we call our unsigned int printing
        jmp doneprtint
    negative:
        movq    %rdi, %r12      # we save the value in r12. We use rdi for printing the '-' sign
        pushq   $45             # we will print the '-'
        movq    $1, %rax        # system call 1 is sys-write
        movq    $1, %rdi        # 1 is stdout
        leaq    (%rsp), %rsi    # rsp holds our address of the to-be-printed character
        movq    $1, %rdx        # we will only write one character at a time
        syscall

        popq    %r10            # pop the '-'

        movq    %r12, %rdi      # move the value again into rdi

        imulq   $-1, %rdi       # multiply it by -1 so it is positive

        call    printuint       # we call our unsigned int printing
    doneprtint:

    movq    %rbp, %rsp
    subq    $8, %rsp
    popq    %r12                # we retrieve value of r12
    movq    %rbp, %rsp          # clear the memory
    popq    %rbp                # get our old rbp back
    ret 


my_printf:
    pushq   %rbp                # save the old rbp
    movq    %rsp, %rbp          # set rbp to new rbp

    pushq   %r12
    pushq   %r13
    pushq   %r14
    pushq   %r15
    
    movq    %rsp, %r14          # now r14 will hold the end of memory that we will have to omit while reading the arguments

    pushq   %r9                 # pushing all the arguments onto the stack
    pushq   %r8
    pushq   %rcx
    pushq   %rdx
    pushq   %rsi

    movq    %rsp, %r15          # now r15 will be our custom rsp that we will move to read the arguments

    movq    %rdi, %r13          # we move the message address into r13
    pushq   $0
    
    printloop:
        movb    (%r13), %r12b   # we move our current character to r12
        cmpb    $0, %r12b       # we check if it isnt the terminating zero
        je     done             # if it is we finish

        cmpb    $37, %r12b      # we check if it is a '%'
        je percent              # if it is then we go to the % case

              
        printcur:               # else

        movq    $1, %rax        # we use 0 rax
        movq    $1, %rdi        # we use 
        movq    %r13, %rsi      # r13 holds our address of the message
        movq    $1, %rdx        # we will print character by character
        syscall

        jmp nextcharacter       # we go to the next character
        percent:
        incq    %r13            # we should move to the next character to see the formating
        movb    (%r13), %r12b   # we move the character to compare it
        
        cmpb    $37, %r12b          # after % we get percent so we print it
        je printcur

        cmpb    $100, %r12b         # after % we get d which is signed int 
        je signedint

        cmpb    $115, %r12b         # after % we get s which is null terminated string 
        je nulstring

        cmpb    $117, %r12b         # after % we get u which is unsigned int 
        je unsignedint

        # none of the options were found so we print the % + following character
        decq    %r13                # we go back so we can print the %
        movb    (%r13), %r12b       # and we set the r12 (our printed character to hold the %)
        jmp     printcur
        signedint:                  # signed int case
        
        movq    (%r15), %rdi 
        call    printint
        addq    $8, %r15

        cmpq    %r14, %r15
        jne     nextcharacter
        addq    $48, %r15
        jmp nextcharacter

        nulstring:                  # string case
        movq    (%r15), %rdi 
        call    printstring
        addq    $8, %r15

        cmpq    %r14, %r15
        jne     nextcharacter
        addq    $48, %r15
        jmp nextcharacter

        unsignedint:                # unsigned int case
        movq    (%r15), %rdi 
        call    printuint
        addq    $8, %r15

        cmpq    %r14, %r15
        jne     nextcharacter
        addq    $48, %r15
        jmp nextcharacter

        nextcharacter:
        incq    %r13
        jmp printloop
    done:

    movq    %rbp, %rsp
    subq    $32, %rsp
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    movq    %rbp, %rsp
    popq    %rbp
    ret

main:
    # Setup stack frame for main (optional in minimal programs)
    pushq   %rbp
    movq    %rsp, %rbp

    # Call myprint with MESSAGE as argument

    
    movq    $hello, %rdi
    movq    $name, %rsi
    movq    $42, %rdx
    movq    $-20, %rcx
    
    //movq    $100, %rdx
    call    my_printf

    /*
    movq    $100, %rdi
    call    printuint
*/
    # Exit system call (rax = 60 for sys_exit, rdi = 0 for status)
    movq    $60, %rax   # sys_exit
    movq    $0, %rdi
    syscall
