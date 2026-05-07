#BLAZING FAST SHA-256 HASHING FOR MIPS🚀🚀🚀🚀🚀🚀🚀
.data
    msg_err:    .asciiz "Error opening file\n"
    newline:    .asciiz "\n"
    hbuffer:    .space  4096

    # SHA-256 round constants K[0..63]
    sha256_K:
        .word 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5
        .word 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5
        .word 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3
        .word 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174
        .word 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc
        .word 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da
        .word 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7
        .word 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967
        .word 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13
        .word 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85
        .word 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3
        .word 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070
        .word 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5
        .word 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3
        .word 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208
        .word 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2

    # SHA-256 initial hash values H[0..7]
    sha256_H:
        .word 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
        .word 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

    sha256_state:  .space 32   # current hash state (8 x 32-bit words)
    sha256_W:      .space 256  # message schedule W[0..63]
    sha256_block:  .space 64   # partial block buffer
    sha256_blen:   .word  0    # bytes in sha256_block
    sha256_totlo:  .word  0    # total bytes fed (low 32 bits)
    sha256_tothi:  .word  0    # total bytes fed (high 32 bits)

.text

# hash_file: $a0 = filename ptr -> returns first word of SHA-256 digest in $v0
#            full 256-bit digest available in sha256_state[0..7]
hash_file:
    addiu $sp, $sp, -16
    sw    $ra, 12($sp)
    sw    $s0,  8($sp)
    sw    $s1,  4($sp)
    sw    $s2,  0($sp)

    jal   sha256_init

    # open file (O_RDONLY)
    li    $a1, 0
    li    $a2, 0
    li    $v0, 13
    syscall
    bltz  $v0, hf_error
    move  $s0, $v0              # fd

hf_read_loop:
    move  $a0, $s0
    la    $a1, hbuffer
    li    $a2, 4096
    li    $v0, 14
    syscall
    blez  $v0, hf_done
    move  $s1, $v0              # bytes read

    la    $a0, hbuffer
    move  $a1, $s1
    jal   sha256_update
    j     hf_read_loop

hf_done:
    move  $a0, $s0
    li    $v0, 16               # close file
    syscall

    jal   sha256_final

    la    $t0, sha256_state
    lw    $v0, 0($t0)           # return first 32-bit word of digest

    lw    $ra, 12($sp)
    lw    $s0,  8($sp)
    lw    $s1,  4($sp)
    lw    $s2,  0($sp)
    addiu $sp, $sp, 16
    jr    $ra

hf_error:
    la    $a0, msg_err
    li    $v0, 4
    syscall
    li    $v0, 10
    syscall


# sha256_init: copy H[0..7] into sha256_state, zero counters
sha256_init:
    la    $t0, sha256_H
    la    $t1, sha256_state
    li    $t2, 8
si_loop:
    lw    $t3, 0($t0)
    sw    $t3, 0($t1)
    addiu $t0, $t0, 4
    addiu $t1, $t1, 4
    addiu $t2, $t2, -1
    bnez  $t2, si_loop
    sw    $zero, sha256_blen
    sw    $zero, sha256_totlo
    sw    $zero, sha256_tothi
    jr    $ra


# sha256_update: $a0 = data ptr, $a1 = byte count
# Buffers data and processes complete 64-byte blocks.
sha256_update:
    addiu $sp, $sp, -16
    sw    $ra, 12($sp)
    sw    $s0,  8($sp)
    sw    $s1,  4($sp)
    sw    $s2,  0($sp)

    move  $s0, $a0              # src ptr
    move  $s1, $a1              # bytes remaining
    lw    $s2, sha256_blen      # current block fill level

    # 64-bit add of length to running total
    lw    $t0, sha256_totlo
    addu  $t0, $t0, $s1
    sltu  $t1, $t0, $s1         # carry
    sw    $t0, sha256_totlo
    lw    $t2, sha256_tothi
    addu  $t2, $t2, $t1
    sw    $t2, sha256_tothi

su_loop:
    beqz  $s1, su_done
    lb    $t0, 0($s0)
    la    $t1, sha256_block
    addu  $t1, $t1, $s2
    sb    $t0, 0($t1)
    addiu $s0, $s0, 1
    addiu $s2, $s2, 1
    addiu $s1, $s1, -1
    li    $t0, 64
    bne   $s2, $t0, su_loop
    la    $a0, sha256_block
    jal   sha256_process_block
    li    $s2, 0
    j     su_loop

su_done:
    sw    $s2, sha256_blen
    lw    $ra, 12($sp)
    lw    $s0,  8($sp)
    lw    $s1,  4($sp)
    lw    $s2,  0($sp)
    addiu $sp, $sp, 16
    jr    $ra


# sha256_final: pad message and process final block(s)
sha256_final:
    addiu $sp, $sp, -8
    sw    $ra, 4($sp)
    sw    $s0, 0($sp)

    lw    $s0, sha256_blen

    # append 0x80
    la    $t0, sha256_block
    addu  $t0, $t0, $s0
    li    $t1, 0x80
    sb    $t1, 0($t0)
    addiu $t0, $t0, 1
    addiu $s0, $s0, 1

    li    $t2, 56
    bgt   $s0, $t2, sf_extra_block

sf_zero_loop:
    li    $t1, 56
    bge   $s0, $t1, sf_write_len
    sb    $zero, 0($t0)
    addiu $t0, $t0, 1
    addiu $s0, $s0, 1
    j     sf_zero_loop

sf_extra_block:
sf_fill64:
    li    $t1, 64
    bge   $s0, $t1, sf_proc_extra
    sb    $zero, 0($t0)
    addiu $t0, $t0, 1
    addiu $s0, $s0, 1
    j     sf_fill64
sf_proc_extra:
    la    $a0, sha256_block
    jal   sha256_process_block
    la    $t0, sha256_block
    li    $s0, 0
sf_zero_loop2:
    li    $t1, 56
    bge   $s0, $t1, sf_write_len
    sb    $zero, 0($t0)
    addiu $t0, $t0, 1
    addiu $s0, $s0, 1
    j     sf_zero_loop2

sf_write_len:
    # bit length = total_bytes * 8 (64-bit shift left by 3)
    lw    $t1, sha256_totlo
    lw    $t2, sha256_tothi
    srl   $t3, $t1, 29
    sll   $t1, $t1, 3
    sll   $t2, $t2, 3
    or    $t2, $t2, $t3

    # write 64-bit big-endian length at block bytes 56..63
    la    $t0, sha256_block
    srl   $t3, $t2, 24
    sb    $t3, 56($t0)
    srl   $t3, $t2, 16
    andi  $t3, $t3, 0xff
    sb    $t3, 57($t0)
    srl   $t3, $t2, 8
    andi  $t3, $t3, 0xff
    sb    $t3, 58($t0)
    andi  $t3, $t2, 0xff
    sb    $t3, 59($t0)
    srl   $t3, $t1, 24
    sb    $t3, 60($t0)
    srl   $t3, $t1, 16
    andi  $t3, $t3, 0xff
    sb    $t3, 61($t0)
    srl   $t3, $t1, 8
    andi  $t3, $t3, 0xff
    sb    $t3, 62($t0)
    andi  $t3, $t1, 0xff
    sb    $t3, 63($t0)

    la    $a0, sha256_block
    jal   sha256_process_block

    lw    $ra, 4($sp)
    lw    $s0, 0($sp)
    addiu $sp, $sp, 8
    jr    $ra


# sha256_process_block: $a0 = ptr to 64-byte block
# Runs the full 64-round SHA-256 compression and adds result to sha256_state.
sha256_process_block:
    addiu $sp, $sp, -40
    sw    $ra, 36($sp)
    sw    $s0, 32($sp)
    sw    $s1, 28($sp)
    sw    $s2, 24($sp)
    sw    $s3, 20($sp)
    sw    $s4, 16($sp)
    sw    $s5, 12($sp)
    sw    $s6,  8($sp)
    sw    $s7,  4($sp)

    # build W[0..15]: read bytes big-endian into 32-bit words
    move  $t8, $a0
    la    $t9, sha256_W
    li    $t7, 0
spb_w_init:
    bge   $t7, 16, spb_w_extend
    lbu   $t0, 0($t8)
    lbu   $t1, 1($t8)
    lbu   $t2, 2($t8)
    lbu   $t3, 3($t8)
    sll   $t0, $t0, 24
    sll   $t1, $t1, 16
    sll   $t2, $t2, 8
    or    $t0, $t0, $t1
    or    $t0, $t0, $t2
    or    $t0, $t0, $t3
    sw    $t0, 0($t9)
    addiu $t8, $t8, 4
    addiu $t9, $t9, 4
    addiu $t7, $t7, 1
    j     spb_w_init

spb_w_extend:
    # W[i] = sigma1(W[i-2]) + W[i-7] + sigma0(W[i-15]) + W[i-16]
    li    $t7, 16
    la    $t9, sha256_W
spb_w_ext_loop:
    bge   $t7, 64, spb_compress
    sll   $t0, $t7, 2

    # sigma1(W[i-2]): ROTR17 xor ROTR19 xor SHR10
    subu  $t6, $t0, 8
    addu  $t6, $t9, $t6
    lw    $t6, 0($t6)
    srl   $t1, $t6, 17
    sll   $t2, $t6, 15
    or    $t1, $t1, $t2
    srl   $t2, $t6, 19
    sll   $t3, $t6, 13
    or    $t2, $t2, $t3
    srl   $t3, $t6, 10
    xor   $t1, $t1, $t2
    xor   $t1, $t1, $t3         # sigma1 -> $t1

    # sigma0(W[i-15]): ROTR7 xor ROTR18 xor SHR3
    subu  $t6, $t0, 60
    addu  $t6, $t9, $t6
    lw    $t6, 0($t6)
    srl   $t2, $t6, 7
    sll   $t3, $t6, 25
    or    $t2, $t2, $t3
    srl   $t3, $t6, 18
    sll   $t4, $t6, 14
    or    $t3, $t3, $t4
    srl   $t4, $t6, 3
    xor   $t2, $t2, $t3
    xor   $t2, $t2, $t4         # sigma0 -> $t2

    # W[i-7]
    subu  $t3, $t0, 28
    addu  $t3, $t9, $t3
    lw    $t3, 0($t3)

    # W[i-16]
    subu  $t4, $t0, 64
    addu  $t4, $t9, $t4
    lw    $t4, 0($t4)

    addu  $t5, $t1, $t2
    addu  $t5, $t5, $t3
    addu  $t5, $t5, $t4
    addu  $t6, $t9, $t0
    sw    $t5, 0($t6)

    addiu $t7, $t7, 1
    j     spb_w_ext_loop

spb_compress:
    # load state into $s0-$s7 (a..h)
    la    $t0, sha256_state
    lw    $s0,  0($t0)
    lw    $s1,  4($t0)
    lw    $s2,  8($t0)
    lw    $s3, 12($t0)
    lw    $s4, 16($t0)
    lw    $s5, 20($t0)
    lw    $s6, 24($t0)
    lw    $s7, 28($t0)

    la    $t9, sha256_W
    la    $t8, sha256_K
    li    $t7, 0

spb_round:
    bge   $t7, 64, spb_update_state

    # W[i]
    sll   $t0, $t7, 2
    addu  $t6, $t9, $t0
    lw    $t0, 0($t6)

    # K[i]
    sll   $t6, $t7, 2
    addu  $t6, $t8, $t6
    lw    $t6, 0($t6)

    # Sigma1(e): ROTR6 xor ROTR11 xor ROTR25
    srl   $t1, $s4, 6
    sll   $t2, $s4, 26
    or    $t1, $t1, $t2
    srl   $t2, $s4, 11
    sll   $t3, $s4, 21
    or    $t2, $t2, $t3
    srl   $t3, $s4, 25
    sll   $t4, $s4, 7
    or    $t3, $t3, $t4
    xor   $t1, $t1, $t2
    xor   $t1, $t1, $t3         # Sigma1 -> $t1

    # Ch(e,f,g) = (e AND f) XOR (NOT e AND g)
    and   $t2, $s4, $s5
    nor   $t3, $s4, $zero
    and   $t3, $t3, $s6
    xor   $t2, $t2, $t3         # Ch -> $t2

    # T1 = h + Sigma1 + Ch + K[i] + W[i]
    addu  $t5, $s7, $t1
    addu  $t5, $t5, $t2
    addu  $t5, $t5, $t6
    addu  $t5, $t5, $t0         # T1 -> $t5

    # Sigma0(a): ROTR2 xor ROTR13 xor ROTR22
    srl   $t1, $s0, 2
    sll   $t2, $s0, 30
    or    $t1, $t1, $t2
    srl   $t2, $s0, 13
    sll   $t3, $s0, 19
    or    $t2, $t2, $t3
    srl   $t3, $s0, 22
    sll   $t4, $s0, 10
    or    $t3, $t3, $t4
    xor   $t1, $t1, $t2
    xor   $t1, $t1, $t3         # Sigma0 -> $t1

    # Maj(a,b,c) = (a AND b) XOR (a AND c) XOR (b AND c)
    and   $t2, $s0, $s1
    and   $t3, $s0, $s2
    and   $t4, $s1, $s2
    xor   $t2, $t2, $t3
    xor   $t2, $t2, $t4         # Maj -> $t2

    # T2 = Sigma0 + Maj
    addu  $t6, $t1, $t2

    # update working variables: h=g g=f f=e e=d+T1 d=c c=b b=a a=T1+T2
    move  $s7, $s6
    move  $s6, $s5
    move  $s5, $s4
    addu  $s4, $s3, $t5
    move  $s3, $s2
    move  $s2, $s1
    move  $s1, $s0
    addu  $s0, $t5, $t6

    addiu $t7, $t7, 1
    j     spb_round

spb_update_state:
    la    $t0, sha256_state
    lw    $t1,  0($t0)
    addu  $t1, $t1, $s0
    sw    $t1,  0($t0)
    lw    $t1,  4($t0)
    addu  $t1, $t1, $s1
    sw    $t1,  4($t0)
    lw    $t1,  8($t0)
    addu  $t1, $t1, $s2
    sw    $t1,  8($t0)
    lw    $t1, 12($t0)
    addu  $t1, $t1, $s3
    sw    $t1, 12($t0)
    lw    $t1, 16($t0)
    addu  $t1, $t1, $s4
    sw    $t1, 16($t0)
    lw    $t1, 20($t0)
    addu  $t1, $t1, $s5
    sw    $t1, 20($t0)
    lw    $t1, 24($t0)
    addu  $t1, $t1, $s6
    sw    $t1, 24($t0)
    lw    $t1, 28($t0)
    addu  $t1, $t1, $s7
    sw    $t1, 28($t0)

    lw    $ra, 36($sp)
    lw    $s0, 32($sp)
    lw    $s1, 28($sp)
    lw    $s2, 24($sp)
    lw    $s3, 20($sp)
    lw    $s4, 16($sp)
    lw    $s5, 12($sp)
    lw    $s6,  8($sp)
    lw    $s7,  4($sp)
    addiu $sp, $sp, 40
    jr    $ra


# print_sha256: prints sha256_state[0..7] as a 64-character lowercase hex string
print_sha256:
    addiu $sp, $sp, -8
    sw    $ra, 4($sp)
    sw    $s0, 0($sp)

    la    $s0, sha256_state
    li    $t7, 8               # 8 words

psh_word_loop:
    beqz  $t7, psh_done
    lw    $t6, 0($s0)          # current word
    li    $t5, 8               # 8 nibbles per word

psh_nibble_loop:
    beqz  $t5, psh_next_word
    srl   $a0, $t6, 28         # isolate top nibble
    andi  $a0, $a0, 0xf
    li    $t4, 10
    blt   $a0, $t4, psh_digit
    addiu $a0, $a0, 87         # 'a' - 10
    j     psh_print
psh_digit:
    addiu $a0, $a0, 48         # '0'
psh_print:
    li    $v0, 11              # print char syscall
    syscall
    sll   $t6, $t6, 4          # shift to next nibble
    addiu $t5, $t5, -1
    j     psh_nibble_loop

psh_next_word:
    addiu $s0, $s0, 4
    addiu $t7, $t7, -1
    j     psh_word_loop

psh_done:
    lw    $ra, 4($sp)
    lw    $s0, 0($sp)
    addiu $sp, $sp, 8
    jr    $ra

#BLAZING FAST SHA-256 HASHING FOR MIPS🚀🚀🚀🚀🚀🚀🚀
