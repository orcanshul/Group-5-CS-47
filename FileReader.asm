.include "./cli.asm"
.include "./cli_macro.asm"
.include "./hash.asm"

.data
errorMsg:   .asciiz "Error: Could not open file."
output:     .asciiz "\nGenerated checksum: "
fileBuffer: .space 128

.text
.globl main

main:
    # Get filename from user

    get_file_name

    # Open file (read-only)
    li $v0, 13
    la $a0, filename
    li $a1, 0
    li $a2, 0
    syscall
    bltz $v0, error
    move $s0, $v0           # save file descriptor

read_loop:
    li $v0, 14
    move $a0, $s0
    la $a1, fileBuffer
    li $a2, 127
    syscall
    move $t0, $v0
    beqz $t0, done
    bltz $t0, error

    la $t1, fileBuffer
    add $t1, $t1, $t0
    sb $zero, 0($t1)        # null-terminate chunk

    li $v0, 4
    la $a0, fileBuffer
    syscall

    j read_loop

done:
    # Close file
    li $v0, 16
    move $a0, $s0
    syscall

    # Compute and print DJB2 hash via hash.asm
    la  $a0, filename
    jal hash_file           # hash -> $v0
    move $s1, $v0           # save before print_string clobbers $v0

    print_string(output)
    print_int($s1)
    la $a0, newline
    li $v0, 4
    syscall

    exit

error:
    li $v0, 4
    la $a0, errorMsg
    syscall
    li $v0, 10
    syscall
