.include "./cli.asm"

.data
errorMsg: .asciiz "Error: Could not open file."
fileBuffer: .space 128
.text
.globl main

main: 
	#Get filename from cli.asm
	jal getFilename
	move $s3,$v0
	
	#Open file
	li $v0, 13		#Syscall for opening file
	move $a0, $s3		#load file into $a0
	li $a1, 0		#set to read only
	li $a2, 0	
	syscall
	
	bltz $v0, error	#checks if file was successfully opened, if not, branches to error
	
	move $s0, $v0		#Save file descriptor 

read_loop:	
	#Read File
	li $v0, 14		#Syscall for reading file
	move $a0, $s0		#Use saved file descriptor
	la $a1, fileBuffer		#Storage location for bytes read
	li $a2, 127		#Set number of bytes to be read at a time
	syscall
	
	move $t0, $v0		
	
	beqz $t0, done
	bltz $t0, error
	
	la $t1, fileBuffer		#Address of start of buffer
	add $t1, $t1, $t0	#Go to position after the last (up to 127) bytes read
	sb $zero, 0($t1)	#End string
	
	#Print to make sure contents of file were read into the buffer
	li $v0,4		
	la $a0, fileBuffer
	syscall
	
	j read_loop

done:
	#Close file
	li $v0, 16		#Syscall to close file
	move $a0, $s0		#Input file descriptor to specify which file to close
	syscall
	
	exit
	
error: 
	#Print error message
	li $v0,4
	la $a0, errorMsg
	syscall
	
	#Exit
	li $v0,10
	syscall
	

