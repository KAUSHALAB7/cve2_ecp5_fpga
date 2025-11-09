# delay.S - Pure assembly delay function
# This bypasses C compiler optimization completely

.section .text
.globl delay_cycles

# void delay_cycles(void)
# Uses t0 and t1 for nested loop
# Outer loop: 50 iterations
# Inner loop: 100,000 iterations per outer
# Total: 5,000,000 cycles ≈ 100ms at 50MHz
delay_cycles:
    li      t0, 50              # outer loop counter

outer_loop:
    li      t1, 100000          # inner loop counter (100k)

inner_loop:
    addi    t1, t1, -1          # decrement inner counter
    bnez    t1, inner_loop      # continue if not zero
    
    addi    t0, t0, -1          # decrement outer counter
    bnez    t0, outer_loop      # continue if not zero
    
    ret                         # return to caller
