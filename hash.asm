# BLAZINGLY FAST HASHING FOR MIPS🚀🚀🚀🚀🚀🚀🚀
#
# Context layout (bytes) at ctx_ptr:
#   0   : state[8] (8 words, 32 bytes)
#   32  : bitlen_hi (word, bits)
#   36  : bitlen_lo (word, bits)
#   40  : buffer_len (word, bytes used in buffer)
#   44  : buffer[64] (64 bytes)
# Total: 108 bytes (caller should allocate at least 112 bytes for alignment)

.data
newline:    .asciiz "\n"         # Kept here since FileReader.asm uses it at the end

sha256_k:
    .word 0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5
    .word 0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5
    .word 0xd807aa98,0x12835b01,0x243185be,0x550c7dc3
    .word 0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174
    .word 0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc
    .word 0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da
    .word 0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7
    .word 0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967
    .word 0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13
    .word 0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85
    .word 0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3
    .word 0xd192e819,0xd6990624,0xf40e3585,0x106aa070
    .word 0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5
    .word 0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3
    .word 0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208
    .word 0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2

.text

# rotr32: $a0=value, $a1=shift (1..31), returns in $v0
rotr32:
    li   $v1, 32
    subu $v1, $v1, $a1
    srlv $t1, $a0, $a1
    sllv $t2, $a0, $v1
    or   $v0, $t1, $t2
    jr   $ra

# sha256_init: $a0 = ctx_ptr
sha256_init:
    li   $t0, 0x6a09e667
    sw   $t0, 0($a0)
    li   $t0, 0xbb67ae85
    sw   $t0, 4($a0)
    li   $t0, 0x3c6ef372
    sw   $t0, 8($a0)
    li   $t0, 0xa54ff53a
    sw   $t0, 12($a0)
    li   $t0, 0x510e527f
    sw   $t0, 16($a0)
    li   $t0, 0x9b05688c
    sw   $t0, 20($a0)
    li   $t0, 0x1f83d9ab
    sw   $t0, 24($a0)
    li   $t0, 0x5be0cd19
    sw   $t0, 28($a0)
    sw   $zero, 32($a0)     # bitlen_hi
    sw   $zero, 36($a0)     # bitlen_lo
    sw   $zero, 40($a0)     # buffer_len
    jr   $ra

# sha256_transform: $a0 = ctx_ptr, $a1 = block_ptr (64 bytes)
sha256_transform:
    addiu $sp, $sp, -360
    sw    $ra, 356($sp)
    sw    $s0, 352($sp)
    sw    $s1, 348($sp)
    sw    $s2, 344($sp)
    sw    $s3, 340($sp)
    sw    $s4, 336($sp)
    sw    $s5, 332($sp)
    sw    $s6, 328($sp)
    sw    $s7, 324($sp)
    sw    $fp, 320($sp)
    move  $fp, $a0          # preserve ctx_ptr (a0 is used for rotr32 calls)

    # w array at $sp (64 words = 256 bytes)
    move  $t9, $sp

    # load first 16 words (big-endian)
    li    $t0, 0
st_load_w:
    bge   $t0, 16, st_w_expand
    sll   $t1, $t0, 2
    addu  $t2, $a1, $t1
    lbu   $t3, 0($t2)
    lbu   $t4, 1($t2)
    lbu   $t5, 2($t2)
    lbu   $t6, 3($t2)
    sll   $t3, $t3, 24
    sll   $t4, $t4, 16
    sll   $t5, $t5, 8
    or    $t7, $t3, $t4
    or    $t7, $t7, $t5
    or    $t7, $t7, $t6
    addu  $t8, $t9, $t1
    sw    $t7, 0($t8)
    addiu $t0, $t0, 1
    j     st_load_w

st_w_expand:
    li    $t0, 16
st_w_loop:
    bge   $t0, 64, st_init_working

    # s0 = rotr(w[i-15],7) ^ rotr(w[i-15],18) ^ (w[i-15]>>3)
    addiu $t1, $t0, -15
    sll   $t2, $t1, 2
    addu  $t3, $t9, $t2
    lw    $t4, 0($t3)
    move  $a0, $t4
    li    $a1, 7
    jal   rotr32
    move  $t5, $v0
    move  $a0, $t4
    li    $a1, 18
    jal   rotr32
    move  $t6, $v0
    srl   $t7, $t4, 3
    xor   $t5, $t5, $t6
    xor   $t5, $t5, $t7

    # s1 = rotr(w[i-2],17) ^ rotr(w[i-2],19) ^ (w[i-2]>>10)
    addiu $t1, $t0, -2
    sll   $t2, $t1, 2
    addu  $t3, $t9, $t2
    lw    $t4, 0($t3)
    move  $a0, $t4
    li    $a1, 17
    jal   rotr32
    move  $t6, $v0
    move  $a0, $t4
    li    $a1, 19
    jal   rotr32
    move  $t7, $v0
    srl   $t8, $t4, 10
    xor   $t6, $t6, $t7
    xor   $t6, $t6, $t8

    # w[i] = w[i-16] + s0 + w[i-7] + s1
    addiu $t1, $t0, -16
    sll   $t2, $t1, 2
    addu  $t3, $t9, $t2
    lw    $t7, 0($t3)

    addiu $t1, $t0, -7
    sll   $t2, $t1, 2
    addu  $t3, $t9, $t2
    lw    $t8, 0($t3)

    addu  $t7, $t7, $t5
    addu  $t7, $t7, $t8
    addu  $t7, $t7, $t6

    sll   $t2, $t0, 2
    addu  $t3, $t9, $t2
    sw    $t7, 0($t3)

    addiu $t0, $t0, 1
    j     st_w_loop

st_init_working:
    lw    $s0, 0($fp)
    lw    $s1, 4($fp)
    lw    $s2, 8($fp)
    lw    $s3, 12($fp)
    lw    $s4, 16($fp)
    lw    $s5, 20($fp)
    lw    $s6, 24($fp)
    lw    $s7, 28($fp)

    li    $t0, 0
st_rounds:
    bge   $t0, 64, st_add_state

    # S1 = rotr(e,6) ^ rotr(e,11) ^ rotr(e,25)
    move  $a0, $s4
    li    $a1, 6
    jal   rotr32
    move  $t1, $v0
    move  $a0, $s4
    li    $a1, 11
    jal   rotr32
    move  $t2, $v0
    move  $a0, $s4
    li    $a1, 25
    jal   rotr32
    move  $t3, $v0
    xor   $t1, $t1, $t2
    xor   $t1, $t1, $t3

    # ch = (e & f) ^ (~e & g)
    and   $t2, $s4, $s5
    nor   $t3, $s4, $zero
    and   $t3, $t3, $s6
    xor   $t2, $t2, $t3

    # temp1 = h + S1 + ch + k[i] + w[i]
    sll   $t4, $t0, 2
    la    $t5, sha256_k
    addu  $t5, $t5, $t4
    lw    $t5, 0($t5)
    addu  $t6, $t9, $t4
    lw    $t6, 0($t6)
    addu  $t7, $s7, $t1
    addu  $t7, $t7, $t2
    addu  $t7, $t7, $t5
    addu  $t7, $t7, $t6

    # S0 = rotr(a,2) ^ rotr(a,13) ^ rotr(a,22)
    move  $a0, $s0
    li    $a1, 2
    jal   rotr32
    move  $t1, $v0
    move  $a0, $s0
    li    $a1, 13
    jal   rotr32
    move  $t2, $v0
    move  $a0, $s0
    li    $a1, 22
    jal   rotr32
    move  $t3, $v0
    xor   $t1, $t1, $t2
    xor   $t1, $t1, $t3

    # maj = (a & b) ^ (a & c) ^ (b & c)
    and   $t2, $s0, $s1
    and   $t3, $s0, $s2
    xor   $t2, $t2, $t3
    and   $t3, $s1, $s2
    xor   $t2, $t2, $t3

    addu  $t8, $t1, $t2     # temp2

    move  $s7, $s6
    move  $s6, $s5
    move  $s5, $s4
    addu  $s4, $s3, $t7
    move  $s3, $s2
    move  $s2, $s1
    move  $s1, $s0
    addu  $s0, $t7, $t8

    addiu $t0, $t0, 1
    j     st_rounds

st_add_state:
    lw    $t0, 0($fp)
    addu  $t0, $t0, $s0
    sw    $t0, 0($fp)
    lw    $t0, 4($fp)
    addu  $t0, $t0, $s1
    sw    $t0, 4($fp)
    lw    $t0, 8($fp)
    addu  $t0, $t0, $s2
    sw    $t0, 8($fp)
    lw    $t0, 12($fp)
    addu  $t0, $t0, $s3
    sw    $t0, 12($fp)
    lw    $t0, 16($fp)
    addu  $t0, $t0, $s4
    sw    $t0, 16($fp)
    lw    $t0, 20($fp)
    addu  $t0, $t0, $s5
    sw    $t0, 20($fp)
    lw    $t0, 24($fp)
    addu  $t0, $t0, $s6
    sw    $t0, 24($fp)
    lw    $t0, 28($fp)
    addu  $t0, $t0, $s7
    sw    $t0, 28($fp)

    lw    $fp, 320($sp)
    lw    $ra, 356($sp)
    lw    $s0, 352($sp)
    lw    $s1, 348($sp)
    lw    $s2, 344($sp)
    lw    $s3, 340($sp)
    lw    $s4, 336($sp)
    lw    $s5, 332($sp)
    lw    $s6, 328($sp)
    lw    $s7, 324($sp)
    addiu $sp, $sp, 360
    jr    $ra

# sha256_update: $a0=ctx_ptr, $a1=data_ptr, $a2=len_bytes
sha256_update:
    addiu $sp, $sp, -40
    sw    $ra, 36($sp)
    sw    $s0, 32($sp)
    sw    $s1, 28($sp)
    sw    $s2, 24($sp)
    sw    $s3, 20($sp)

    move  $s0, $a0          # ctx
    move  $s1, $a1          # data
    move  $s2, $a2          # len

    # bitlen += len*8 (64-bit)
    lw    $t0, 36($s0)      # lo
    lw    $t1, 32($s0)      # hi
    sll   $t2, $s2, 3
    srl   $t3, $s2, 29
    addu  $t4, $t0, $t2
    sltu  $t5, $t4, $t0
    addu  $t1, $t1, $t3
    addu  $t1, $t1, $t5
    sw    $t1, 32($s0)
    sw    $t4, 36($s0)

    lw    $s3, 40($s0)      # buffer_len

su_loop:
    beqz  $s2, su_done
    lbu   $t0, 0($s1)
    addiu $t1, $s0, 44
    addu  $t1, $t1, $s3
    sb    $t0, 0($t1)
    addiu $s1, $s1, 1
    addiu $s3, $s3, 1
    addiu $s2, $s2, -1

    li    $t2, 64
    bne   $s3, $t2, su_loop

    sw    $zero, 40($s0)
    move  $a0, $s0
    addiu $a1, $s0, 44
    jal   sha256_transform
    move  $s3, $zero
    j     su_loop

su_done:
    sw    $s3, 40($s0)
    lw    $ra, 36($sp)
    lw    $s0, 32($sp)
    lw    $s1, 28($sp)
    lw    $s2, 24($sp)
    lw    $s3, 20($sp)
    addiu $sp, $sp, 40
    jr    $ra

# sha256_final: $a0=ctx_ptr, $a1=out_ptr (32 bytes)
sha256_final:
    addiu $sp, $sp, -32
    sw    $ra, 28($sp)
    sw    $s0, 24($sp)
    sw    $s1, 20($sp)

    move  $s0, $a0
    move  $s1, $a1

    # append 0x80
    lw    $t0, 40($s0)
    addiu $t1, $s0, 44
    addu  $t1, $t1, $t0
    li    $t2, 0x80
    sb    $t2, 0($t1)
    addiu $t0, $t0, 1
    sw    $t0, 40($s0)

    # pad with zeros until buffer_len == 56; if overflow, pad to 64 and transform
sf_check:
    lw    $t0, 40($s0)
    li    $t3, 56
    blt   $t0, $t3, sf_zero_to_56
    li    $t4, 64
    beq   $t0, $t3, sf_write_len
    blt   $t0, $t4, sf_zero_to_64
    # buffer_len == 64
    move  $a0, $s0
    addiu $a1, $s0, 44
    jal   sha256_transform
    sw    $zero, 40($s0)
    j     sf_check

sf_zero_to_56:
    lw    $t0, 40($s0)
    li    $t3, 56
    beq   $t0, $t3, sf_write_len
    addiu $t1, $s0, 44
    addu  $t1, $t1, $t0
    sb    $zero, 0($t1)
    addiu $t0, $t0, 1
    sw    $t0, 40($s0)
    j     sf_zero_to_56

sf_zero_to_64:
    lw    $t0, 40($s0)
    li    $t4, 64
    beq   $t0, $t4, sf_check
    addiu $t1, $s0, 44
    addu  $t1, $t1, $t0
    sb    $zero, 0($t1)
    addiu $t0, $t0, 1
    sw    $t0, 40($s0)
    j     sf_zero_to_64

sf_write_len:
    # write 64-bit bitlen big-endian at buffer[56..63]
    lw    $t6, 32($s0)      # hi
    lw    $t7, 36($s0)      # lo
    addiu $t0, $s0, 44
    addiu $t0, $t0, 56

    srl   $t1, $t6, 24
    sb    $t1, 0($t0)
    srl   $t1, $t6, 16
    sb    $t1, 1($t0)
    srl   $t1, $t6, 8
    sb    $t1, 2($t0)
    sb    $t6, 3($t0)

    srl   $t1, $t7, 24
    sb    $t1, 4($t0)
    srl   $t1, $t7, 16
    sb    $t1, 5($t0)
    srl   $t1, $t7, 8
    sb    $t1, 6($t0)
    sb    $t7, 7($t0)

    move  $a0, $s0
    addiu $a1, $s0, 44
    jal   sha256_transform

    # output digest as big-endian bytes
    li    $t0, 0
sf_out:
    bge   $t0, 8, sf_done
    sll   $t1, $t0, 2
    addu  $t2, $s0, $t1
    lw    $t3, 0($t2)
    srl   $t4, $t3, 24
    sb    $t4, 0($s1)
    srl   $t4, $t3, 16
    sb    $t4, 1($s1)
    srl   $t4, $t3, 8
    sb    $t4, 2($s1)
    sb    $t3, 3($s1)
    addiu $s1, $s1, 4
    addiu $t0, $t0, 1
    j     sf_out

sf_done:
    lw    $ra, 28($sp)
    lw    $s0, 24($sp)
    lw    $s1, 20($sp)
    addiu $sp, $sp, 32
    jr    $ra

# print_hex_digest: $a0 = ptr to 32-byte digest
print_hex_digest:
    addiu $sp, $sp, -24
    sw    $ra, 20($sp)
    sw    $s0, 16($sp)
    sw    $s1, 12($sp)
    move  $s0, $a0
    li    $s1, 32

phd_loop:
    beqz  $s1, phd_done
    lbu   $t0, 0($s0)
    srl   $t1, $t0, 4
    andi  $t2, $t0, 0x0f

    move  $a0, $t1
    jal   _print_hex_nibble
    move  $a0, $t2
    jal   _print_hex_nibble

    addiu $s0, $s0, 1
    addiu $s1, $s1, -1
    j     phd_loop

phd_done:
    lw    $ra, 20($sp)
    lw    $s0, 16($sp)
    lw    $s1, 12($sp)
    addiu $sp, $sp, 24
    jr    $ra

_print_hex_nibble:
    slti  $t0, $a0, 10
    bnez  $t0, _phn_digit
    addiu $t1, $a0, 55      # 'A' - 10
    j     _phn_emit
_phn_digit:
    addiu $t1, $a0, 48      # '0'
_phn_emit:
    move  $a0, $t1
    li    $v0, 11           # print_char
    syscall
    jr    $ra
