.include "./cli.asm"
.include "./cli_macro.asm"
.include "./hash.asm"

.data
errorMsg:   .asciiz "Error: Could not open file."
output:     .asciiz "\nGenerated checksum: "
fileBuffer: .space 128
.align 2
sha_ctx:    .space 112
.align 2
sha_out:    .space 32

.text
.globl main

main:
    # Get filename from user
    get_file_name

    # Initialize SHA-256 context
    la $a0, sha_ctx
    jal sha256_init

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
    move $s2, $v0           # Changed to $s2 to preserve across jal
    beqz $s2, done
    bltz $s2, error

    # Hash the current chunk (update running SHA-256 context)
    la $a0, sha_ctx
    la $a1, fileBuffer
    move $a2, $s2
    jal sha256_update

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

    # Finalize and print SHA-256 digest
    la $a0, sha_ctx
    la $a1, sha_out
    jal sha256_final

    print_string(output)
    la $a0, sha_out
    jal print_hex_digest
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
