.data
base:   .asciz  "%ld"
power:   .asciz  "%ld"

.text
authors:    .asciz "\nNames: Maksymilian Sobiech and Jokūbas Jasiūnas\nNetIDs: msobiech and jjasiunas\nAssignment 2: Recursion\n"
query:      .asciz "\nEnter the n:\n"
verificationInput:   .asciz "\nEntered base is: %ld\nEntered power is: %ld\n"
verificationCondition:  .asciz "\nCurrent n is : %ld\n"
result:                .asciz "\nThe result is %ld\n"
.global main

main:
    # prologue
    push %rbp                               # keep the stack aligned
    movq %rsp ,%rbp
    
    
    movq $0, %rax                           # there will be no SSE registers in use by printf
    movq $authors, %rdi                     # moving the message to print to rdi for printf to use as an argument

    call printf                             # printing the initial message

    movq $0, %rax                           # there will be no SSE registers in use by printf
    movq $query, %rdi                       # moving the message to print to rdi for printf to use as an argument
    call printf                             # printing the query for the base

    subq $16, %rsp                          # reserve the space for the first input
    movq $0, %rax                           # there will be no SSE registers in use by scanf
    movq $base, %rdi                        # param1 : input format string
    leaq -16(%rbp), %rsi                    # param2 : address of the reserved space
    call scanf                              # scanning for the first input

    movq -16(%rbp),%rdi                     # moving n to the first argument register

    addq $16, %rsp                          # freeing the memory                      

    
    call factorial                          # calling the subroutine for raising the base to the given power

    movq $result, %rdi                      # param1: input format string
    movq %rax, %rsi                         # result from %rax moved to %rsi in order for it to replace %ld during the print
    movq $0, %rax                           # there will be no SSE registers in use by printf
    call printf                             # printing the result

    movq $0, %rdi                           # if it ends here then everything went well so we return 0
    call exit


# ******************************************************************
# * Subroutine: factorial                                          *
# * Description: This subroutine calculates the factorial of given *
# * number                                                         *
# * Parameters: One integer passed in %rdi                         *
# * Return value: Return value in %rax                             *
# ******************************************************************

factorial:
    pushq %rbp                            # pushing base pointer to the stack
    movq %rsp, %rbp
    subq $8, %rsp                         # correcting the alignment
    
    #solution  
    cmpq $0, %rdi                         # check if %rdi(current n) is bigger than n
    jg if
    jmp else
    if:                                   # if n > 0 then calculate
        pushq %rdi                        # push current n to stack
        decq %rdi                         # n = n-1;
        call factorial                    # calling the recursion of factorial
        popq %rdi                         # recover the current n from stack
        mulq %rdi                         # multiplication of current n and %rax(our result)  %rax = %rax*%rdi
        jmp endfac                        #if I got here then the recursion cycle has ended and I am able to end the subroutine
    else:                                  
        movq $1, %rax                     #if n <= 0 then return 1
    endfac:
    #end of solution
    movq %rbp, %rsp                       # clearing the local variables from the stack
    popq %rbp                             # restoring the base pointer location

    ret                                   # return from the subroutine
