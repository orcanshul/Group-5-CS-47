.include "./cli_macro.asm"

.data
prompt: .asciiz "Enter file path: "

filename:   .space 128
buffer:     .space 1024

error_message: .asciiz "Failed to open the file."
output: .asciiz "\nGenerated checksum: "

.text
.globl main

main:
    	print_string(prompt)
    	read_filename

    	la $t0, filename

remove_newline: 
	# when reading the file name, there is a newline bit in the back. 
	# ex. "hello.txt" becomes "hello.txt\n\0"
	# this loop gets rid of the '\n'
    	lb $t1, 0($t0)

    	beq $t1, 10, replace_null 
    	beqz $t1, done_cleaning

    	addi $t0, $t0, 1
    	j remove_newline

replace_null:
    	sb $zero, 0($t0)

done_cleaning:
    	print_string(output)


    exit