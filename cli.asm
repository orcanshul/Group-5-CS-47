.include "./cli_macro.asm"
.include "./hash.asm"

.data
prompt:         .asciiz "Enter file path: "
filename:       .space 128
error_message:  .asciiz "Failed to open the file."
output:         .asciiz "\nGenerated checksum: "

.text
.globl getFilename

getFilename:
    print_string(prompt)
    read_filename

    la $t0, filename

remove_newline:
    # strip trailing '\n' left by syscall 8
    lb $t1, 0($t0)
    beq  $t1, 10, replace_null
    beqz $t1, done_cleaning
    addi $t0, $t0, 1
    j remove_newline

replace_null:
    sb $zero, 0($t0)

done_cleaning:
    # call hash_file with filename, result in $v0
    la  $a0, filename
    jal hash_file
    move $s0, $v0            # save hash before print_string clobbers $v0

    print_string(output)
    print_int($s0)
    la  $a0, newline
    li  $v0, 4
    syscall

    exit
