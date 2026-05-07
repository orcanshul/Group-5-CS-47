.data
prompt:   .asciiz "Path: "
filename: .space 128
echo_msg: .asciiz "Read: ["
close_b:  .asciiz "]\n"
len_msg:  .asciiz "Len: "
nl:       .asciiz "\n"

.text
.globl main
main:
    # print prompt
    la  $a0, prompt
    li  $v0, 4
    syscall

    # read string from stdin
    la  $a0, filename
    li  $a1, 128
    li  $v0, 8
    syscall

    # echo it back
    la  $a0, echo_msg
    li  $v0, 4
    syscall

    la  $a0, filename
    li  $v0, 4
    syscall

    la  $a0, close_b
    li  $v0, 4
    syscall

    # try to open it
    la  $a0, filename
    li  $a1, 0
    li  $a2, 0
    li  $v0, 13
    syscall

    bge $v0, $zero, ok
    la  $a0, nl
    li  $v0, 4
    syscall
    la  $a0, filename
    li  $v0, 4
    syscall
    li  $v0, 10
    syscall
ok:
    la  $a0, ok_msg
    li  $v0, 4
    syscall
    li  $v0, 10
    syscall

.data
ok_msg: .asciiz "Open OK\n"
