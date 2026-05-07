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
    li $s1, 5381            # initialize hash seed

read_loop:
    li $v0, 14
    move $a0, $s0
    la $a1, fileBuffer
    li $a2, 127
    syscall
    move $s2, $v0           # Changed to $s2 to preserve across jal
    beqz $s2, done
    bltz $s2, error

    # Hash the current chunk
    la $a0, fileBuffer
    move $a1, $s2
    move $a2, $s1           # Pass current running hash state
    jal hash_buffer
    move $s1, $v0           # Update running hash state from $v0

    # Print chunk
    la $t1, fileBuffer
    add $t1, $t1, $s2
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

    # Print sha 256 hash (already computed in loop)
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