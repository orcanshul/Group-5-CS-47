#BLAZING FAST HASHING FOR MIPS🚀🚀🚀🚀🚀🚀🚀
.data
    newline:    .asciiz "\n"         # Kept here since FileReader.asm uses it at the end

.text
# hash_buffer: $a0 = buffer ptr, $a1 = bytes to read, $a2 = current hash
# returns updated DJB2 hash in $v0
hash_buffer:
    move $t0, $a0            # buffer pointer
    li   $t1, 0              # byte counter
    move $v0, $a2            # current hash

hf_hash_loop:
    # hash each byte: hash = hash*33 + byte
    bge  $t1, $a1, hf_done
    lb   $t2, 0($t0)
    sll  $t3, $v0, 5
    addu $v0, $v0, $t3
    addu $v0, $v0, $t2
    addiu $t0, $t0, 1
    addiu $t1, $t1, 1
    j    hf_hash_loop

hf_done:
    jr   $ra

#BLAZING FAST HASHING FOR MIPS🚀🚀🚀🚀🚀🚀🚀