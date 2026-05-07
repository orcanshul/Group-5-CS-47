.data
    prompt:     .asciiz "Enter filename: "
    msg_hash:   .asciiz "Hash: "
    msg_err:    .asciiz "Error opening file\n"
    newline:    .asciiz "\n"
    filename:   .space  256             # input buffer for filename
    buffer:     .space  4096            # file read buffer

.text
.globl main

main:
    # print prompt, read filename
    la   $a0, prompt
    li   $v0, 4
    syscall

    la   $a0, filename
    li   $a1, 256
    li   $v0, 8
    syscall

    # replace newline with null
    la   $t0, filename
strip_loop:
    lb   $t1, 0($t0)
    beqz $t1, open_file
    li   $t2, 10
    bne  $t1, $t2, next_char
    sb   $zero, 0($t0)
    j    open_file
next_char:
    addiu $t0, $t0, 1
    j    strip_loop

open_file:
    # open file, bail on error
    la   $a0, filename
    li   $a1, 0              # O_RDONLY
    li   $a2, 0
    li   $v0, 13
    syscall
    bltz $v0, file_error
    move $s0, $v0            # fd
    li   $s1, 5381           # DJB2 seed

read_loop:
    # read next chunk
    move $a0, $s0
    la   $a1, buffer
    li   $a2, 4096
    li   $v0, 14
    syscall
    blez $v0, close_file     # EOF or error
    move $s2, $v0            # bytes read

    la   $t0, buffer
    li   $t1, 0

hash_loop:
    # hash each byte: hash * 33 + byte
    bge  $t1, $s2, read_loop
    lb   $t2, 0($t0)
    sll  $t3, $s1, 5
    addu $s1, $s1, $t3
    addu $s1, $s1, $t2
    addiu $t0, $t0, 1
    addiu $t1, $t1, 1
    j    hash_loop

close_file:
    # close, print hash, exit
    move $a0, $s0
    li   $v0, 16
    syscall

    la   $a0, msg_hash
    li   $v0, 4
    syscall
    move $a0, $s1
    li   $v0, 1
    syscall
    la   $a0, newline
    li   $v0, 4
    syscall

    li   $v0, 10
    syscall

file_error:
    la   $a0, msg_err
    li   $v0, 4
    syscall
    li   $v0, 10
    syscall
