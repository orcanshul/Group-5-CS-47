# Web entry point for the MIPS checksum tool.
# Mirrors cli.asm logic but places `main:` before the hash.asm include
# so MARS headless mode (-sm) starts at the right instruction.
# Original cli.asm / hash.asm are untouched.

.include "./cli_macro.asm"

.data
prompt:   .asciiz "Enter file path: "
filename: .space 128
output:   .asciiz "\nGenerated checksum: "

.text
.globl main
main:
    print_string(prompt)
    read_filename

    la $t0, filename
strip_nl:
    lb   $t1, 0($t0)
    beq  $t1, 10, do_null
    beqz $t1, hashing
    addi $t0, $t0, 1
    j    strip_nl
do_null:
    sb $zero, 0($t0)

hashing:
    la  $a0, filename
    jal hash_file
    move $s0, $v0

    print_string(output)
    print_int($s0)
    la  $a0, newline          # newline is defined inside hash.asm below
    li  $v0, 4
    syscall
    exit

.include "./hash.asm"
