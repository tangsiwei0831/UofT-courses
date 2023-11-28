# Demo for painting
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
############
#
#	finish milestone 1/2/3
#
#

.data
	displayAddress: .word 0x10008000
	red:		.word 0xff0000
	green:		.word 0x00ff00
	blue:		.word 0x0000ff
    	yellow: 	.word 0xfff86b
    	white: 		.word 0xffffff
    	black : 	.word 0x000000	
   	
    	doodler:	.word   8
    	doodle:		.word	1668,1792,1796, 1800, 1920, 1928
    	jumpheight: 	.word   10
    	obstacle: 	.word	28, 0, 0, 0
    	sleeptime: 	.word   50
.text
.globl	main	

main:
  	lw 	$s0, displayAddress
  	lw 	$s1, white
  	lw	$s2, green
  	lw	$s3, black
  	lw	$s4, yellow
  	
init_platforms:
	la	$t0, obstacle	
	li 	$t1, 4
	li	$t2, 0
	
init_loop:
	move	$a0, $t2
	jal 	generate_platform
	sw 	$v0, ($t0) # save X of current
	addi	$t0, $t0, 4
	addi	$t2, $t2, 1
	blt 	$t2, $t1, init_loop	
 
loop:
  	jal	draw_backgroud
  	jal	draw_platforms
  	la  	$a0, doodle
  	jal	draw_doodle
  	
  	jal	input
 	beq	$v0, 0x71, exit
 	
  	move	$a0, $v0
  	jal	move_doodle
  	
 	la 	$t0, doodler 
	lw 	$t1, 4($t0) # get Y of doodler

  	
  	lw 	$a0, sleeptime
  	jal	sleep
  	
  	j	loop
exit:
	li $v0, 10 # terminate the program gracefully
	syscall 		


###########################
#	draw the digit
#------------------------
#	argument: no
#    	return: no
#

 ##########################
 #	draw backgroud
 #------------------------
 #	argument: no
 #    	return: no
 
draw_backgroud:	
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
  	li 	$t0, 0        		# Initialize beginning  
  	li 	$t1, 1024     		# Initialize end  	
draw_backgroud_loop:	
  	beq 	$t0, $t1, draw_backgroud_done
  	sll 	$t2, $t0, 2
  	add 	$t3, $t2, $s0
  	sw  	$s1, 0($t3)	        # paint the unit white.  
  	addi 	$t0, $t0, 1    		# Increment counter  
  	j 	draw_backgroud_loop 
draw_backgroud_done:
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
 #########################
 #	draw doodle
 #------------------------
 #	argument: a0 <- doodle address
 #    	return: no
		  			  	
draw_doodle:
	addi	$sp, $sp, -4
	sw	$ra, ($sp)    	
        li  	$t0, 0		# Index of the loop
        li  	$t1, 0		# Index of the doodle array
	la 	$t2, doodler
	lw	$t6, ($t2)
	sll	$t6, $t6, 2
	
#move_down:
##	beq  	$t0, 6, draw_doodle_start	# if $t0 = 6, Done
#        addi 	$t0, $t0, 1			# $t0 = $t0 + 1
#        sll 	$t5, $t1, 2			# $t5 = 4 * $t1 (index)
#        add  	$t3, $a0, $t5			# $t3 = &doodle + 4 * Index
#        lw	$t4, ($t3)
#        addi	$t4, $t4, 128
#        sw	$t4, ($t3)
#	addi 	$t1, $t1, 1			# Index = Index + 1
#	j	move_down
	
draw_doodle_start:	
        li  	$t0, 0		# Index of the loop
        li  	$t1, 0		# Index of the doodle array	
draw_doodle_loop:
        beq  	$t0, 6, draw_doodle_done	# if $t0 = 6, Done
        addi 	$t0, $t0, 1			# $t0 = $t0 + 1
        sll 	$t5, $t1, 2			# $t5 = 4 * $t1 (index)
        add  	$t3, $a0, $t5			# $t3 = &doodle + 4 * Index
        lw   	$t5, 0($t3)			# $t5 = doodle[Index]
#       	beq	$t5, 3072, move_down
 #      	beq	$t5, 3968, end_game
       	
        add	$t5, $t5, $t6			#
        add  	$t4, $t5, $s0			# $t6 = doodle[Index] + displayAddress
        sw   	$s2, 0($t4)			# load green on the bit map at $t5
        addi 	$t1, $t1, 1			# Index = Index + 1
        j 	draw_doodle_loop
       
draw_doodle_done:
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra
     
 end_game:
 	li $v0, 32
	li $a0, 100
	syscall
	
	lw 	$ra, 0($sp) # pop $ra of drawDoodler caller func
	addi 	$sp, $sp, 4
		
	jal 	draw_backgroud
	
		    
     
 #########################
 #	draw platforms
 #------------------------
 #	argument: no
 #    	return: no
 #	   	         	   	
draw_platforms:
	addi	$sp, $sp, -4
	sw	$ra, ($sp)    
        
    	li 	$t0, 0		# loop index $t4 = 0
    	la 	$t1, obstacle	# $t5 = &obstacle   
    	   
get_platforms:

        beq 	$t0, 4, draw_platforms_done	# if $t4 == len(Obstacle), jump to DOBDONE
        li 	$t2, 4				# $t7 = 4
        mult 	$t0, $t2			# index * 4 ( the byte of index $t4)
        mflo 	$t2				# $t7 = index * 4
        add 	$t2, $t1, $t2			# $t7 = &Obstacle[$t4]
        lw 	$t3, 0($t2)			# $t8 = value of Obstacle[$t4]
        add 	$t3, $t3, $s0			# $t8 = a certain index on displayAddress
        li	$t8, 0
get_platforms_loop:        
        beq	$t8, 8, get_platforms_continue

        sw 	$s3, 0($t3)				# load green color onto the index of displayAddress
        addi	$t3, $t3, 4
        addi	$t8, $t8, 1
        j	get_platforms_loop
get_platforms_continue:     
        addi 	$t0,$t0,1				# index $t4 = $t4 + 1
     
        j 	get_platforms		

draw_platforms_done:
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra        	   		   		   	

 #########################
 #	keyboard input
 #------------------------
 #	argument: no
 #  	return	: $v0 <- input value
 
input:
	addi 	$sp, $sp, -4
	sw 	$ra, 0($sp)
	lui 	$t0, 0xffff
read_wait:
	lw 	$t1, 0($t0) 		#control
	andi 	$t1, $t1, 0x0001
	beq 	$t1, $zero, read_wait
	lw 	$v0, 4($t0)		#input device is ready, so read
	lw 	$ra, 0($sp)
	addi 	$sp, $sp, 4
	jr 	$ra	

##################################
#	move	doodle
#--------------------------------
#	argument: a0 <- the input value
#  	return	: $v0 <- no
#
move_doodle:
	addi 	$sp, $sp, -4
	sw 	$ra, 0($sp)
	move	$t0, $a0 
	beq 	$t0, 0x6a, move_left 	# check if "j"
	beq 	$t0, 0x6b, move_right 	# check if "k"

move_left:
	la 	$t0, doodler
	lw 	$t1, 0($t0)
	addi 	$t1, $t1, -2
	bltz 	$t1, left_board_reached
	j 	move_left_continue
left_board_reached:
	li 	$t1, 31
move_left_continue:
	sw 	$t1, 0($t0)
	j 	move_doodle_end
	
move_right:
	la 	$t0, doodler
	lw 	$t1, 0($t0)
	addi 	$t1, $t1, 2
	bgt 	$t1, 31, right_board_reached
	j 	move_right_continue
right_board_reached:
	li 	$t1, 0
move_right_continue:
	sw 	$t1, 0($t0)
	j move_doodle_end
move_doodle_end:	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

generate_platform:
	addi 	$sp, $sp, -16
	sw 	$ra, 0($sp)
	sw	$t0, 4($sp)
	sw	$t1, 8($sp)
	sw	$t2, 12($sp)
	
	move	$t0, $a0
	sll	$t0, $t0, 3
	
	li	$a1, 8
	jal	random_number
	move	$t1, $v0
	add	$t1, $t1, $t0
	
	li 	$t0, 128
	mult 	$t1, $t0
	mflo 	$t1
	
	li	$a0, 0
	li	$a1, 23
	jal	random_number
	move	$t0, $v0
	sll	$t2, $t0, 2
	add	$t2, $t2, $t1
	move	$v0, $t2	 
	
	lw 	$ra, 0($sp)
	lw	$t0, 4($sp)
	lw	$t1, 8($sp)
	lw	$t2, 12($sp)
	addi 	$sp, $sp, 16
	jr $ra	

##################################
#	generate random number
#--------------------------------
#	argument: a0 <- min value
#		  a1 <- max value
#  	return	: $v0 <- random value
#
random_number:
	addi 	$sp, $sp, -4
	sw 	$ra, 0($sp)

	li 	$v0, 42
	syscall
	move 	$v0, $a0
	
	lw 	$ra, 0($sp)
	addi 	$sp, $sp, 4
	jr 	$ra

##################################
#	sleep
#--------------------------------
#	argument: a0 <- sleep time
#
#  	return	: no
#
sleep:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	li $v0, 32
	syscall

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
