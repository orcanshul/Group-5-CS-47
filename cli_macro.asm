.macro print_string(%arg)
    li $v0, 4
    la $a0, %arg
    syscall
.end_macro

.macro read_filename
    li $v0, 8
    la $a0, filename
    li $a1, 128
    syscall
.end_macro

.macro exit
    li $v0, 10
    syscall
.end_macro