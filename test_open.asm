.data
filepath: .asciiz "test_input.txt"
ok_msg:   .asciiz "File opened OK, fd="
err_msg:  .asciiz "Open failed\n"
nl:       .asciiz "\n"

.text
.globl main
main:
    la   $a0, filepath
    li   $a1, 0
    li   $a2, 0
    li   $v0, 13
    syscall
    bltz $v0, fail

    move $a0, $v0
    la   $a0, ok_msg
    li   $v0, 4
    syscall
    li   $v0, 1
    li   $a0, 3
    syscall
    la   $a0, nl
    li   $v0, 4
    syscall
    j    done

fail:
    la   $a0, err_msg
    li   $v0, 4
    syscall

done:
    li   $v0, 10
    syscall
