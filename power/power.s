.data
base:   .asciz  "%ld"
power:   .asciz  "%ld"

.text
authors:    .asciz "\nNames: Maksymilian Sobiech and Jokūbas Jasiūnas\nNetIDs: msobiech and jjasiunas\nAssignment 1: Powers\n"
queryBase:      .asciz "\nEnter the base:\n"
queryPower:      .asciz "\nEnter the power:\n"
verificationInput:   .asciz "\nEntered base is: %ld\nEntered power is: %ld\n"
verificationCondition:  .asciz "\nEntered power is postive\n"
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
    movq $queryBase, %rdi                   # moving the message to print to rdi for printf to use as an argument
    call printf                             # printing the query for the base

    subq $16, %rsp                          # reserve the space for the first input
    movq $0, %rax                           # there will be no SSE registers in use by scanf
    movq $base, %rdi                        # param1 : input format string
    leaq -16(%rbp), %rsi                    # param2 : address of the reserved space
    call scanf                              # scanning for the first input


    movq $0, %rax                           # there will be no SSE registers in use by printf
    movq $queryPower, %rdi                  # moving the message to print to rdi for printf to use as an argument
    call printf                             # printing the query for the base


    subq $16, %rsp                          # reserve the space for the second input
    movq $0, %rax                           # there will be no SSE registers in use by scanf
    movq $power, %rdi                       # param1 : input format string
    leaq -32(%rbp), %rsi                    # param2 : address of the reserved space
    call scanf                              # scanning for the second input

    movq -16(%rbp),%rdi                     # moving base value to the first argument register
    movq -32(%rbp),%rsi                     # moving power value to the second argument register

    addq $32, %rsp                          # freeing the memory

    
    call pow                                # calling the subroutine for raising the base to the given power

    movq $result, %rdi                      # param1: input format string
    movq %rax, %rsi                         # result from %rax moved to %rsi in order for it to replace %ld during the print
    movq $0, %rax                           # there will be no SSE registers in use by printf
    call printf                             # printing the result
    
    #epilogue

    movq $0, %rdi                           # if it ends here then everything went well so we return 0
    call exit


# *******************************************************************************
# * Subroutine: pow                                                             *
# * Description: This subroutine raises the base to the given power             *
# * Parameters: Two integers passed as parameters in %rdi(base) and %rsi(power) *
# * Return value: Return value in %rax                                          *
# *******************************************************************************
pow:
    pushq %rbp                            # pushing base pointer to the stack
    movq %rsp, %rbp
    
    cmpq $0, %rsi                         # comparing power to 0 
                                          # (if not then we end the subroutine with the return of 1[assuming that power is 0 then])
    jg ifcode

    elsecode:
        movq $1, %rax                     # we return 1 because the power is 0
        jmp end
    ifcode:
        movq $1, %rax                     # we set the %rax to 1 because that will be our register that keeps our result
        loop:
            mulq %rdi                     # we multiply our current result which is in %rax by %rdi which has our base and the result of multiplication is in %rax
            decq %rsi                     # we decrement the rsi because it is keeping how many times more should we multiply
            cmpq $0 ,%rsi                 # we check if we have any multiplications left
            jg loop                       # if yes then we jump to the start of the loop again

    end:
        movq %rbp, %rsp                   # clearing the local variables from the stack
        popq %rbp                         # restoring the base pointer location

        ret                               # return from the subroutine
