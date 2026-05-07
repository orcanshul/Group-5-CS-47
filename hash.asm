#BLAZING FAST HASHING FOR MIPS🚀🚀🚀🚀🚀🚀🚀
.data
    msg_err:    .asciiz "Error opening file\n"
    newline:    .asciiz "\n"
    hbuffer:    .space  4096            # separate name to avoid conflict with cli.asm

.text
# hash_file: $a0 = filename ptr -> returns SHA256 hash in $v0
hash_file:
    # save callee-saved registers
    addiu $sp, $sp, -12
    sw    $s0, 0($sp)
    sw    $s1, 4($sp)
    sw    $s2, 8($sp)

    # open file (O_RDONLY), $a0 still holds filename
    li   $a1, 0
    li   $a2, 0
    li   $v0, 13
    syscall
    bltz $v0, hf_error
    move $s0, $v0            # fd
    li   $s1, 5381           # SHA256 seed

hf_read_loop:
    # read next chunk into hbuffer
    move $a0, $s0
    la   $a1, hbuffer
    li   $a2, 4096
    li   $v0, 14
    syscall
    blez $v0, hf_close       # 0 = EOF, negative = error
    move $s2, $v0            # bytes read

    la   $t0, hbuffer
    li   $t1, 0

hf_hash_loop:
    # hash each byte: hash = hash*33 + byte
    bge  $t1, $s2, hf_read_loop
    lb   $t2, 0($t0)
    sll  $t3, $s1, 5
    addu $s1, $s1, $t3
    addu $s1, $s1, $t2
    addiu $t0, $t0, 1
    addiu $t1, $t1, 1
    j    hf_hash_loop

hf_close:
    move $a0, $s0
    li   $v0, 16             # close file
    syscall
    move $v0, $s1            # return hash

    # restore callee-saved registers
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    addiu $sp, $sp, 12
    jr   $ra

hf_error:
    la   $a0, msg_err
    li   $v0, 4
    syscall
    li   $v0, 10
    syscall

#BLAZING FAST — HASHING FOR MIPS🚀🚀🚀🚀🚀🚀🚀