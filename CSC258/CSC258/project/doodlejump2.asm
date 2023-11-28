####################################################################### 
#CSC258H5S Fall 2020 Assembly Final Project
# University of Toronto, St. George## Student: Name, Student Number
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
## Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3/4/5 (choose the one the applies)
#
# Which approved additional features have been implemented?# (See the assignment handout for the list of additional features)
# 1/2/3/4
#rertry/ Game over
#scoreboard
# Any additional information that the TA needs to know:# - (write here, if any)
######################################################################





.data
	displayAddress: .word 0x10008000
	red:		.word 0xff0000
	green:		.word 0x00ff00
	blue:		.word 0x0000ff
    yellow: 	.word 0xfff86b
    white: 		.word 0xffffff
    black : 	.word 0x000000	
    staticPlatform:	.word -1:200 
    dynamicPlatform: .word 1536, 1700, 2212, 2632, 2888, -1 
    doodle: 	.word 3032  
    scoreBoard:	.word 108
    fragilePlatform: .word 3080, 2020, 1596, -1
    gameOverMessage: .asciiz "Game Over"
    scoreMessage: .asciiz "Score "
    startGameMessage: .asciiz "Press r to start the game"
    newLine:  .asciiz "\n"
	groundPlatform: .word 3672, 3800, 3928, 4056, 3648, 3776, 3904, 4032
	letterS: .word 0, 4, 8, 128, 256, 260, 264, 392, 520, 516, 512, -1 # 0
	letterE: .word 0, 4, 8, 128, 256, 260, 264, 384, 512, 516, 520, -1 # 1
	letterP: .word 0, 4, 8, 128, 136, 256, 260, 264, 384, 512, -1 # 2
	letterO: .word 0, 4, 8, 128, 136, 256, 264, 384, 392, 512, 516, 520, -1 # 3
	letterG: .word 0, 4, 8, 128, 136, 256, 260, 264, 392, 520, 648, 644, 640, 512, -1 # 4
	letterR: .word 0, 128, 256, 384, 512, 132, 8, 140, -1 # 5
	letterA: .word 4, 128, 136, 256, 260, 264, 384, 392, 512, 520, -1 # 6
	letterW: .word 0, 8, 16, 128, 136, 144, 256, 264, 272, 388, 396, -1 # 7
	letterM: .word 128, 256, 384, 4, 136, 12, 144, 272, 400, -1 # 8
	exclamation: .word 0, 128, 256, 512, -1 # 9 
	letterB: .word 0, 128, 256, 384, 512, 260, 264, 392, 520, 516, -1 # 10
	letterC: .word 0, 4, 8, 128, 256, 384, 512, 516, 520, -1 # 11
	letterD: .word 8, 136, 264, 260, 256, 384, 392, 512, 516, 520, -1 # 12
	letterF: .word 0, 4, 8, 128, 256, 260, 264, 384, 512, -1 # 13
	letterH: .word 0, 8, 128, 136, 256, 260, 264, 384, 392, 512, 520, -1 # 14
	letterI: .word 0, 256, 384, 512, -1 # 15 width is 1
	letterJ: .word 0, 4, 8, 132, 260, 388, 512, 516, -1 # 16
	letterK: .word 0, 8, 128, 132, 256, 384, 388, 512, 520, -1 #17
	letterL: .word 0, 128, 256, 384, 512, 516, 520, -1 # 18
	letterN: .word 128, 132, 136, 256, 264, 384, 392, 512, 520, -1 # 19
	letterQ: .word 0, 4, 8, 128, 136, 256, 260, 264, 392, 520, -1 # 20 
	letterT: .word 0, 4, 8, 132, 260, 388, 516, -1 # 21
	letterU: .word 0, 128, 256, 384, 512, 516, 520, 392, 264, 136, 8, -1 # 22
	letterV: .word 0, 128, 256, 384, 516, 392, 264, 136, 8, -1 # 23
	letterX: .word 0, 8, 132, 260, 388, 512, 520, -1 # 24
	letterY: .word 0, 8, 132, 260, 388, 516, -1 # 25
	letterZ: .word 0, 4, 8, 136, 260, 384, 512, 516, 520, -1 # 26
	wowLetters: .word 7, 3, 7, -1
	awesomeLetters: .word 6, 7, 1, 0, 3, 8, 1, -1
	poggersLetters: .word 2, 3, 4, 4, 1, 5, 0, -1
	playerName: .word -1:7
.text

game_start:
	game_start_init:
		addi $t0, $zero, 0
		j paint_game_start_page

	game_start_loop:
		beq $t0, 10000, exit
		addi $a0, $zero, 1000
		jal sleep
		jal keyboard_control
		# This needs to be modified 
		beq $v0, 0, game_update
		beq $v0, 1, exit
		j game_start_loop

	paint_game_start_page:
		# Task1: Design of the game start page
		paint_game_start_page_init:
			beq $t0, 0, paint_game_start_page_end

			init_letterH:
			addi $t7, $zero, 1824
			la $t3, letterH
			j after_init_letter
			
			init_letterI:
			addi $t7, $zero, 1868
			la $t3, letterI
			j after_init_letter


			after_init_letter:
				addi $t0, $t0, 1
				addi $t1, $zero, 0
				addi $t2, $zero, 0
				lw $t5, displayAddress
				add $t5, $t5, $t7
				lw $t6, green

		paint_game_start_page_loop:
			lw $t4, 0($t3)
			beq $t4, -1, paint_game_start_page_init
			add $t7, $t5, $t4 # Get address on the screen
			sw $t6, 0($t7) 
			addi $t3, $t3, 4
		j paint_game_start_page_loop

		paint_game_start_page_end:
			j game_start_loop
game_update:
	game_update_initialize:
		addi $s0, $zero, 0        	# Initialize beginning  
  		addi $s1, $zero, 100		# Initialize end 		# Store position of platform 1
  		addi $s2, $zero, 0		# Initialize score
  		addi $s3, $zero, 0		# Store keyboard Input
		lw $s4, doodle
		addi $s5, $zero, 0		# Whether the platform move down
		addi $t6, $zero, 0		# This maintains t6

		# Init 20 static platforms randomly despite there is overlap
		# Input of random number generator is a1, the upper bound shoud be
		build_platform_init:
			addi $t0, $zero, 0			# Initialize t0 to be count
			la  $t1, staticPlatform		# Get staticPlatform

		build_platform_loop:
			beq $t0, 10, build_ground_platform_init # Init 50 platforms

			addi $a1, $zero, 192 
			jal random_number_generator 
			# Generate number between 32/4 = 8 (Every level has at most eight platforms)
			# 8 * 32 = 256, 8 * 5 = 40, 8 * 3 = 24, thus generate a number between 40 and 256 - 24 = 232 thus 40 - 232
			# Then 0 - 192, add 40 to the final result, then mutiply by 16 
			# Therefore, 40 levels for first five levels, 
			# The first five levels are occupied

			addi $t2, $v0, 40
			mul $t2, $t2, 16 # Find the start position of the platform
			
  			sw $t2, 0($t1)

			addi $t1, $t1, 4 # Keep Track of static
			addi $t0, $t0, 1

			j build_platform_loop
		
		build_ground_platform_init:
			addi $t2, $zero, 0
			la $t3, groundPlatform

		build_ground_platform_loop:

			beq $t2, 32, build_ground_platform_end
			
			add $t5, $t3, $t2
			lw $t4, 0($t5)
			sw $t4, 0($t1)
			addi $t1, $t1, 4

			addi $t2, $t2, 4
			j build_ground_platform_loop
		build_ground_platform_end:
				j game_update_loop

	game_update_loop:
		beq $s0, $s1, game_update_end
		
		addi $a0, $zero, 1000
		jal sleep
		
		jal keyboard_control
		addi $s3, $v0, 0
		
		jal paint_background
		
		addi $t0, $zero, 105
		div $s2, $t0
		mfhi $a0
		jal paint_notification
		addi $s6, $v0, 0

		addi $a0, $s0, 0
		addi $a1, $s5, 0
		addi $a2, $zero, 0
		jal paint_static_platform
		
		
		addi $a0, $s0, 0
		addi $a1, $s3, 0 # a1 gives input for doodle direction
		jal paint_doodle
		beq $v0, 1, game_over # 0 if nothing happened, Return 1 if gameover, 2 if drop 
		addi $s5, $v0, 0
		
		addi $a0, $s2, 0
		jal paint_score_board
		
		addi $s2, $s2, 1
		
		addi $s0, $s0, 1    			# Increment counter 
		 
  		j game_update_loop 

	game_update_end:
		j exit
		
	game_over:
		jal paint_background
		
		li $v0, 4
		la $a0, gameOverMessage
		syscall
		
		li $v0, 4
		la $a0, newLine
		syscall
		
		li $v0, 4
		la $a0, scoreMessage
		syscall
		
		li $v0, 1
		move $a0, $s2
		syscall
		
		li $v0, 4
		la $a0, newLine
		syscall
		
		li $v0, 4
		la $a0, startGameMessage
		syscall
		
		j game_start

paint_notification:
	paint_notification_init:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	beq $a0, 200, paint_name
	beq $a0, 20, paint_awesome_init
	beq $a0, 21, paint_awesome_init
	beq $a0, 22, paint_awesome_init
	beq $a0, 23, paint_awesome_init
	beq $a0, 24, paint_awesome_init
	beq $a0, 50, paint_poggers_init
	beq $a0, 51, paint_poggers_init
	beq $a0, 52, paint_poggers_init
	beq $a0, 53, paint_poggers_init
	beq $a0, 54, paint_poggers_init
	beq $a0, 100, paint_wow_init
	beq $a0, 101, paint_wow_init
	beq $a0, 102, paint_wow_init
	beq $a0, 103, paint_wow_init
	beq $a0, 104, paint_wow_init
	addi $v0, $zero, 0
	j paint_notification_end

	paint_awesome_init:
		la $t0, awesomeLetters
		j paint_notification_outer

	paint_poggers_init:
		la $t0, poggersLetters
		j paint_notification_outer

	paint_wow_init:
		la $t0, wowLetters
		j paint_notification_outer
	
	paint_name:
		la $t0, playerName
		j paint_notification_outer


	paint_notification_outer:
		paint_notification_outer_init:
			addi $t7, $zero, 0 # Starting positib
			
		paint_notification_outer_loop:
			lw $t1, 0($t0)
			beq $t1, -1, paint_notification_outer_end
			addi $a0, $t1, 0
			jal letter_index_map
			addi $a0, $v0, 0 # This is the letter array
			addi $a1, $t7, 0 # This is the start position 
			add $t7, $t7, $v1
			
			
			# color using s6
			jal paint_letter
			addi $t0, $t0, 4
			j paint_notification_outer_loop

		paint_notification_outer_end:
			addi $v0, $zero, 1
			j paint_notification_end

	paint_notification_end:
	lw $ra, 0($sp) # store the pointer for function
	addi $sp, $sp, 4
	jr $ra

paint_letter:
	paint_letter_init:
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		
		addi $t2, $a0, 0 # Array
		addi $t3, $a1, 0 # Start paint positio

		addi $t5, $zero, 5
		div $s0, $t5
		mfhi $a0 
		jal color_index_map
		addi $t5, $v0, 0 # t5 is the color 
		lw $t6, displayAddress # This is the address
		add $t3, $t3, $t6 # Start paint position

	paint_letter_loop:
		lw $t4, 0($t2)
		beq $t4, -1, paint_letter_end
		add $t4, $t4, $t3
		
		sw $t5, 0($t4)
		
		addi $t2, $t2, 4
		j paint_letter_loop

	paint_letter_end:
		lw $ra, 0($sp) # store the pointer for function
		addi $sp, $sp, 4
		
		jr $ra

paint_background:
	paint_background_init:
  		lw $t0, displayAddress
  		lw $t1, white
    		addi $t2, $zero, 0        		# Initialize beginning  
  		addi $t3, $zero, 8192			# Initialize end 
  		
  	paint_background_loop:			     			
  		beq $t2, $t3, paint_background_end	# Logical left shift 2 bits of t2 (multiply by 4), store it in t4 
  		add $t4, $t2, $t0			# Add t4 with the starting position, get t5 to paint
  		sw  $t1, 0($t4)	        		# paint the unit white.  
  		addi $t2, $t2, 4    			# Increment counter  
  		j paint_background_loop 
  	
  	paint_background_end:
  		jr $ra
paint_fragile_platform:
	j paint_fragile_platform_init
 

        
paint_static_platform:
	j paint_static_platform_init
	paint_fragile_platform_init:
		la  $t1, fragilePlatform
		j paint_fragile_platform_after_address
	paint_static_platform_init:
    		la  $t1, staticPlatform		# Load address of platform array
			paint_fragile_platform_after_address:
        	addi $t2, $zero, 0			# Index of the loop
        	lw  $t0, displayAddress		# $t0 = displayAddress		
        	addi $t4, $zero, 0
        	
			beq $a1, 2, static_movedown
			j after_static_movedown
			
			static_movedown:
				addi $t4, $t4, 256
				j after_static_movedown
			
			after_static_movedown:
        		j paint_platform_loop
        	

paint_platform_procedure:
	paint_platform_loop:
        addi $sp, $sp, -4
		sw $t1, 0($sp) # store the current pointer position for the array
		
		addi $sp, $sp, -4
		sw $ra, 0($sp) # store the return pointer for function
        	
        	beq $t2, 800, paint_platform_end	# if $t2 = $t5, the number of elements, done     
		
		# la  $t1, staticPlatform
  		add $t6, $t2, $t1  	# Get position of platform in array, array position is $t1, current 
		lw $t7, 0($t6)  	# counter is $t2, add them to get t6, and get element in t6

		beq $t7, -1, paint_platform_end		# If position is uninitialized, return 
  		
  		add $t7, $t7, $t4	# Get position on the screen, 
		  					# and we keep the convention to store position in $t7
		# Now, it is to time to check all kinds of locations
		# Before doing this, we need to store all important temp registers into stack
		addi $sp, $sp, -4
		sw $t0, 0($sp)

		addi $sp, $sp, -4
		sw $t2, 0($sp)

		addi $sp, $sp, -4
		sw $t3, 0($sp)
  		
		addi $sp, $sp, -4
		sw $t4, 0($sp)

		# First, check if position is on the boundary
  		add $a0, $zero, $t7
		addi $a1, $zero, 16 # This can be modified to different length of the platform
		jal check_on_boundary

		beq $v0, 1, platform_move_right_branch
		beq $v0, 2, platform_move_left_branch
		j after_move_boundary

		platform_move_right_branch:
			addi $t7, $t7, 8
			j after_move_boundary
			
		platform_move_left_branch:
			addi $t7, $t7, -8
			j after_move_boundary
			
		after_move_boundary:
		
		add $a0, $zero, $t7
		jal check_on_bottom

		beq $v0, 1, reset_platform

		# Now, it is time to recover those temp registers
		lw $t4, 0($sp)
		addi $sp, $sp, 4

		lw $t3, 0($sp)
		addi $sp, $sp, 4

		lw $t2, 0($sp)
		addi $sp, $sp, 4

		lw $t0, 0($sp)
		addi $sp, $sp, 4
  		
  		add $a0, $t7, $t0	# Paint position in the array
		sw $t7, 0($t6)		# Store the finalized pointer in the array
  						
  		jal platform_normal	# Paint green on the screen
  		
  		reset_platform_end:

  		addi $t2, $t2, 4	# $t2 = $t2 + 4
  		
  		lw $ra, 0($sp) # store the pointer for function
		addi $sp, $sp, 4
		
  		lw $t1, 0($sp)
		addi $sp, $sp, 4
		
  		j paint_platform_loop
  		
  	reset_platform:
		
		addi $a1, $zero, 32 	# This gives the input of random number
  		jal random_number_generator
  	
  		mul $t7, $v0, 4
  		
  		addi $t7, $t7, 768
  		sw $t7, 0($t6)

		lw $t4, 0($sp)
		addi $sp, $sp, 4

		lw $t3, 0($sp)
		addi $sp, $sp, 4

		lw $t2, 0($sp)
		addi $sp, $sp, 4

		lw $t0, 0($sp)
		addi $sp, $sp, 4
		
		j reset_platform_end
  		
  	paint_platform_end:
  		lw $ra, 0($sp) 
		addi $sp, $sp, 4
		
  		lw $t1, 0($sp)
		addi $sp, $sp, 4
		
  		jr $ra
  
platform_shape:	
	platform_normal:	# Paint normal platform: _
		beq $a2, 0, color_red
		beq $a2, 1, color_green
		beq $a2, 2, color_yellow # Fragile
		color_red:
			lw  $t3, blue # Paint trap platform with red color
			j start_paint_platform
		color_green:
			lw  $t3, green # Paint trap platform with red color
			j start_paint_platform
		color_yellow:
			lw  $t3, yellow # Paint trap platform with red color
			j start_paint_platform

		start_paint_platform:	
		addi $t1, $a0, 0
		sw $t3, 0($t1)
		addi $t1, $t1, 4
		sw $t3, 0($t1)
		addi $t1, $t1, 4
		sw $t3, 0($t1)
		addi $t1, $t1, 4
		sw $t3, 0($t1)	
		jr $ra	
		 
				
paint_doodle:
	paint_doodle_init:
		addi $sp, $sp, -4
		sw $ra, 0($sp)

		addi $t4, $zero, 0 # This is for movement of doodle

		# To do: this two numbers need to be modified
		addi $t1, $s4, 0
		beq $a1, 16, handle_doodle_move_left
		beq $a1, 17, handle_doodle_move_right	
		
		cannot_move:
		handle_doodle_move_end:

		addi $t1, $s4, 0
		add $a0, $t1, $t4
		addi $a0, $a0, 384
		addi $a0, $a0, -8
		jal check_on_bottom
		beq $v0, 1, handle_doodle_lose
		
		addi $t1, $s4, 0
		add $a0, $t1, $t4
		addi $a0, $a0, 384 # We check if the bottom of the doodle touches platform
		addi $a0, $a0, -4

		la $a1, staticPlatform  # Static
		addi $a2, $zero, 0
		jal check_on_platform
		beq $v0, 1, handle_doodle_on_platform

		la $a1, dynamicPlatform  # Dynamic
		addi $a2, $zero, 1
		jal check_on_platform
		beq $v0, 1, handle_doodle_on_platform

		la $a1, fragilePlatform  # Fragile
		addi $a2, $zero, 2
		jal check_on_platform
		j handle_doodle_off_platform

		handle_doodle_platform_end:

		add $s4, $t4, $s4 # Update position for doodle 
		
		j paint_doodle_procedure
	
	doodle_handlers:
		handle_doodle_move_left:
			addi $a0, $t1, -4
			addi $a1, $zero, 12
			jal check_on_boundary
			beq $v0, 1, cannot_move
			addi $t4, $t4, -4
			j handle_doodle_move_end
			
		handle_doodle_move_right:
			addi $a0, $t1, 0
			addi $a1, $zero, 12
			jal check_on_boundary
			beq $v0, 1, cannot_move
			addi $t4, $t4, 4
			j handle_doodle_move_end

		handle_doodle_on_platform:
			addi $t4, $t4, -256
			addi $t9, $zero, 1
			j handle_doodle_platform_end
		
		handle_doodle_off_platform:
			addi $t4, $t4, 128
			j handle_doodle_platform_end
			
		handle_doodle_lose: # return to the main, let main handle this 
			lw $ra, 0($sp) 
			addi $sp, $sp, 4
			
			addi $v0, $zero, 1 # If lose return 1
			jr $ra
	
	paint_doodle_procedure:	
		lw  $t0, displayAddress	
		addi $t1, $s4, 0	
		lw  $t2, black
		add $t3, $t0, $t1 # Get position on the screen
		
		sw $t2, 0($t3)
		addi $t3, $t3, 124
		sw $t2, 0($t3)
		addi $t3, $t3, 4
		sw $t2, 0($t3)
		addi $t3, $t3, 4
		sw $t2, 0($t3)
		addi $t3, $t3, 120
		sw $t2, 0($t3)
		addi $t3, $t3, 8
		sw $t2, 0($t3)
		
		j paint_doodle_end
		
	paint_doodle_end:
		beq $t9, 1 hit_platform_end
		addi $v0, $zero, 0 # If nothing happened, return 0
		
		lw $ra, 0($sp) 
		addi $sp, $sp, 4
		jr $ra
		
		hit_platform_end:
			addi $t9, $zero, 0
			lw $ra, 0($sp) 
			addi $sp, $sp, 4
			addi $v0, $zero, 2 # If hit platform, return 2
			jr $ra	
		
paint_score_board:
	paint_score_board_init:
		lw  $t0, displayAddress	
		lw  $t1, scoreBoard	
		lw  $t2, yellow
		addi $t3, $a0, 0
		add $t1, $t1, $t0
		addi $t4, $zero, 0 # Count the position of the digit
		
	paint_score_board_loop:
		beq $s6, 1, paint_score_board_end
		beq $t3, 0, paint_score_board_end
		
		lw  $t1, scoreBoard
		add $t1, $t1, $t0
		add $t1, $t1, $t4
		
		addi $t5, $zero, 10
		div $t3, $t5
        	mfhi $t3	# Store $a0 % 5
        	
        	addi $a0, $t3, 0
        	
        	beq $t3, 0, paint_number_zero # t3 is for strong digits
        	paint_number_zero_return:
        		beq $t3, 1, paint_number_one
        	paint_number_one_return:
        		beq $t3, 2, paint_number_two
        	paint_number_two_return:
        		beq $t3, 3, paint_number_three
        	paint_number_three_return:
        		beq $t3, 4, paint_number_four
        	paint_number_four_return:
        		beq $t3, 5, paint_number_five
        	paint_number_five_return:
        		beq $t3, 6, paint_number_six
        	paint_number_six_return:
        		beq $t3, 7, paint_number_seven
        	paint_number_seven_return:
        		beq $t3, 8, paint_number_eight
        	paint_number_eight_return:
        		beq $t3, 9, paint_number_nine
        	paint_number_nine_return:
        	
        	mflo $t3	# Store $a0 // 5
        	addi $t4, $t4, -16
        	
        	j paint_score_board_loop
		
	paint_score_board_procedure:
		paint_number_zero:
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 120
			sw $t2, 0($t1)
			addi $t1, $t1, 8
			sw $t2, 0($t1)
			addi $t1, $t1, 120
			sw $t2, 0($t1)
			addi $t1, $t1, 8
			sw $t2, 0($t1)
			addi $t1, $t1, 120
			sw $t2, 0($t1)
			addi $t1, $t1, 8
			sw $t2, 0($t1)
			addi $t1, $t1, 120
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			
			j paint_number_zero_return
			
		paint_number_one:
			addi $t1, $t1, 8
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			
			j paint_number_one_return
		
		paint_number_two:
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, -4
			sw $t2, 0($t1)
			addi $t1, $t1, -4
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			
			j paint_number_two_return
			
		paint_number_three:
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, -4
			sw $t2, 0($t1)
			addi $t1, $t1, -4
			sw $t2, 0($t1)
			addi $t1, $t1, 136
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, -4
			sw $t2, 0($t1)
			addi $t1, $t1, -4
			sw $t2, 0($t1)
			
			j paint_number_three_return
		
		paint_number_four:
			sw $t2, 0($t1)
			addi $t1, $t1, 8
			sw $t2, 0($t1)
			addi $t1, $t1, 120
			sw $t2, 0($t1)
			addi $t1, $t1, 8
			sw $t2, 0($t1)
			addi $t1, $t1, 120
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			
			j paint_number_four_return
		
		paint_number_five:
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 120
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, -4
			sw $t2, 0($t1)
			addi $t1, $t1, -4
			sw $t2, 0($t1)
			
			j paint_number_five_return
		
		paint_number_six:
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 120
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, -8
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			
			j paint_number_six_return
		
		paint_number_seven:
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			
			j paint_number_seven_return
		
		paint_number_eight:
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 120
			sw $t2, 0($t1)
			addi $t1, $t1, 8
			sw $t2, 0($t1)
			addi $t1, $t1, 120
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 120
			sw $t2, 0($t1)
			addi $t1, $t1, 8
			sw $t2, 0($t1)
			addi $t1, $t1, 120
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			
			j paint_number_eight_return
			
		paint_number_nine:
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 120
			sw $t2, 0($t1)
			addi $t1, $t1, 8
			sw $t2, 0($t1)
			addi $t1, $t1, 120
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 4
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			
			j paint_number_nine_return
				
	paint_score_board_end:
			jr $ra

keyboard_control:
# To do 2: Fix this according to the list (20 min), index, and two outputs
	keyboard_control_init:
		lw $t0, 0xffff0000
		beq $t0, 1, keyboard_control_respond
		j invalid_input
		
	keyboard_control_respond:
		lw $t1, 0xffff0004
		beq $t1, 0x41, a_input
		beq $t1, 0x61, a_input
		beq $t1, 0x42, b_input
		beq $t1, 0x62, b_input
		beq $t1, 0x43, c_input
		beq $t1, 0x63, c_input
		beq $t1, 0x44, d_input
		beq $t1, 0x64, d_input
		beq $t1, 0x45, e_input
		beq $t1, 0x65, e_input
		beq $t1, 0x46, f_input
		beq $t1, 0x66, f_input
		beq $t1, 0x47, g_input
		beq $t1, 0x67, g_input
		beq $t1, 0x48, h_input
		beq $t1, 0x68, h_input
		beq $t1, 0x49, i_input
		beq $t1, 0x69, i_input
		beq $t1, 0x6a, j_input
		beq $t1, 0x4a, j_input
		beq $t1, 0x6b, k_input
		beq $t1, 0x4b, k_input
		beq $t1, 0x4c, l_input
		beq $t1, 0x6c, l_input
		beq $t1, 0x4d, m_input
		beq $t1, 0x6d, m_input
		beq $t1, 0x4e, n_input
		beq $t1, 0x6e, n_input
		beq $t1, 0x4f, o_input
		beq $t1, 0x6f, o_input
		beq $t1, 0x50, p_input
		beq $t1, 0x70, p_input
		beq $t1, 0x51, q_input
		beq $t1, 0x71, q_input
		beq $t1, 0x52, r_input
		beq $t1, 0x72, r_input
		beq $t1, 0x53, s_input
		beq $t1, 0x73, s_input
		beq $t1, 0x54, t_input
		beq $t1, 0x74, t_input
		beq $t1, 0x55, u_input
		beq $t1, 0x75, u_input
		beq $t1, 0x56, v_input
		beq $t1, 0x76, v_input
		beq $t1, 0x57, w_input
		beq $t1, 0x77, w_input
		beq $t1, 0x58, x_input
		beq $t1, 0x78, x_input
		beq $t1, 0x59, y_input
		beq $t1, 0x79, y_input
		beq $t1, 0x5a, z_input
		beq $t1, 0x7a, z_input
		beq $t1, 0x20, space_input

	keyboard_control_end:
		invalid_input:
			addi $v0, $zero, -1
			jr $ra
		r_input:
			addi $v0, $zero, 0
			jr $ra
		e_input:
			addi $v0, $zero, 1
			jr $ra
		p_input:
			addi $v0, $zero, 2
			jr $ra
		o_input:
			addi $v0, $zero, 3
			jr $ra
		g_input:
			addi $v0, $zero, 4
			jr $ra
		s_input:
			addi $v0, $zero, 5
			jr $ra
		a_input:
			addi $v0, $zero, 6
			jr $ra
		w_input:
			addi $v0, $zero, 7
			jr $ra
		m_input:
			addi $v0, $zero, 8
			jr $ra
		b_input:
			addi $v0, $zero, 10
			jr $ra
		c_input:
			addi $v0, $zero, 11
			jr $ra
		d_input:
			addi $v0, $zero, 12
			jr $ra
		f_input:
			addi $v0, $zero, 13
			jr $ra
		h_input:
			addi $v0, $zero, 14
			jr $ra
		i_input:
			addi $v0, $zero, 15
			jr $ra
		j_input:
			addi $v0, $zero, 16
			jr $ra
		k_input:
			addi $v0, $zero, 17
			jr $ra
		l_input:
			addi $v0, $zero, 18
			jr $ra
		n_input:
			addi $v0, $zero, 19
			jr $ra
		q_input:
			addi $v0, $zero, 20
			jr $ra
		t_input:
			addi $v0, $zero, 21
			jr $ra
		u_input:
			addi $v0, $zero, 22
			jr $ra
		v_input:
			addi $v0, $zero, 23
			jr $ra
		x_input:
			addi $v0, $zero, 24
			jr $ra
		y_input:
			addi $v0, $zero, 25
			jr $ra
		z_input:
			addi $v0, $zero, 26
			jr $ra
		space_input:
			addi $v0, $zero, 27
			jr $ra

random_number_generator:
	random_number_generator_init:
		 li $v0, 42
		 li $a0, 0
		 syscall
		 j random_number_generator_end
	
	random_number_generator_end:
		addi $v0, $a0, 0
		jr $ra
		
sleep:
	 li $v0, 32
	 syscall
	 jr $ra

# Please avoid using register 4
interaction_check:
	check_on_platform:
		check_on_platform_init:
			addi $t0, $zero, 0 # This maintains counter of the loop
			add $t1, $zero, $a1 # This maintains the address of the platform
			addi $t2, $a0, 0	 # This stores position of the doodle
			
		check_on_platform_loop:
			beq  $t0, 800, check_on_platform_end
			
			add $t3, $t1, $t0
			lw $t5, 0($t3) # Position of the current platform
			beq $t5, -1, check_on_platform_end # If the position is uninit

			addi $t5, $t5, -128
			addi $t5, $t5, -8
			beq $t5, $t2, react_platform # If doodle touches platform, then react
			addi $t5, $t5, 4
			beq $t5, $t2, react_platform # We also need to make sure the whole platform touches doodle
			addi $t5, $t5, 4
			beq $t5, $t2, react_platform
			addi $t5, $t5, 4
			beq $t5, $t2, react_platform
			addi $t5, $t5, 4
			beq $t5, $t2, react_platform
			addi $t5, $t5, 4
			beq $t5, $t2, react_platform
			
			addi $t0, $t0, 4 
			j check_on_platform_loop
		
		check_on_platform_end: 		
			addi $v0, $zero, 0
			jr $ra
			
			react_platform:
				beq $a2, 2, react_fragile_platform
				addi $v0, $zero, 1
				jr $ra

			react_fragile_platform:
				addi $sp, $sp, -4
				sw $ra, 0($sp)
				
				addi $a1, $zero, 32 	# This gives the input of random number
  				jal random_number_generator
  	
  				mul $t7, $v0, 4
  		
  				addi $t7, $t7, 768

				sw $t7, 0($t3)
				addi $v0, $zero, 1 # If on freagile, return 
				
				lw $ra, 0($sp)
				addi $sp, $sp, 4
				
				jr $ra

	check_on_boundary:
		check_on_boundary_init:
			addi $t2, $a0, 0	 # This stores leftmost position of an object
			addi $t3, $a1, 0  # This stores length of this object
			
			addi $t0, $zero, 128
			div $t2, $t0
			mfhi $t1
				
			beq $t1, 0, on_left_boundary_react 

			add $t2, $t2, $t3
			div $t2, $t0
			mfhi $t1
			beq $t1, 124, on_right_boundary_react  
			
			j check_on_boundary_end		
			
		check_on_boundary_end:
			addi $v0, $zero, 0
			jr $ra
			on_left_boundary_react:
				addi $v0, $zero, 1
				jr $ra
				
			on_right_boundary_react:
				addi $v0, $zero, 2
				jr $ra
		
	check_on_bottom:
		check_on_bottom_init:
			addi $t2, $a0, 0
			addi $t0, $zero, 4095
	
			slt $t1, $t2, $t0    # checks if $s9(4095) > $t7
			beq $t1, $zero, on_bottom_react # if $s0 < $s1, goes to label3
			
			j check_on_bottom_end
			
		check_on_bottom_end:	
			addi $v0, $zero, 0
			jr $ra
			on_bottom_react:
				addi $v0, $zero, 1
				jr $ra

movement:
	move_right:
		add $t4, $zero, $a0 # This stores number of steps moving right 
		mul $t4, $t4, 4
		addi $v0, $t4, 0 # Return the number of positions after moving right
		jr $ra
	
	move_left:
		add $t4, $zero, $a0 # This stores number of steps moving right 
		mul $t4, $t4, -4
		addi $v0, $t4, 0 # Return the number of positions after moving right
		jr $ra
		
	move_down:
		add $t4, $zero, $a0 # This stores number of steps moving right 
		mul $t4, $t4, 128
		addi $v0, $t4, 0 # Return the number of positions after moving right
		jr $ra

	move_up:
		add $t4, $zero, $a0 # This stores number of steps moving right 
		mul $t4, $t4, -128
		addi $v0, $t4, 0 # Return the number of positions after moving right
		jr $ra
		
print:
	addi $sp, $sp, -4
	sw $v0, 0($sp) # store the pointer for function
	
	addi $sp, $sp, -4
	sw $a0, 0($sp) # store the pointer for function
		
	li $v0, 1
	la $a0, newLine
	syscall
		
	li $v0, 1
	add $a0, $zero, $v0
	syscall
		
	lw $a0, 0($sp) # store the pointer for function
	addi $sp, $sp, 4
		
  	lw $v0, 0($sp)
	addi $sp, $sp, 4

letter_index_map:
# To do 1: Compelete this according to the list (20 min)
	beq $a0, 0, S
	beq $a0, 1, E
	beq $a0, 2, P
	beq $a0, 3, O
	beq $a0, 4, G
	beq $a0, 5, R
	beq $a0, 6, A
	beq $a0, 7, W
	beq $a0, 8, M
	beq $a0, 9, ex
	beq $a0, 10, B
	beq $a0, 11, C
	beq $a0, 12, D
	beq $a0, 13, F
	beq $a0, 14, H
	beq $a0, 15, I
	beq $a0, 16, J
	beq $a0, 17, K
	beq $a0, 18, L
	beq $a0, 19, N
	beq $a0, 20, Q
	beq $a0, 21, T
	beq $a0, 22, U
	beq $a0, 23, V
	beq $a0, 24, X
	beq $a0, 25, Y
	beq $a0, 26, Z

	S:
		la $v0, letterS
		addi $v1,$zero, 16
		jr $ra
	E:
		la $v0, letterE
		addi $v1,$zero, 16
		jr $ra
		
	P:	
		la $v0, letterP
		addi $v1,$zero, 16
		jr $ra
	O:	
		la $v0, letterO
		addi $v1,$zero, 16
		jr $ra
	G:	
		la $v0, letterG
		addi $v1,$zero, 16
		jr $ra
	R:	
		la $v0, letterR
		addi $v1,$zero, 20
		jr $ra
	A:	
		la $v0, letterA
		addi $v1,$zero, 16
		jr $ra
	W:	
		la $v0, letterW
		addi $v1,$zero, 24
		jr $ra
	M:	
		la $v0, letterM
		addi $v1,$zero, 24
		jr $ra
	ex:	
		la $v0, exclamation
		addi $v1,$zero, 8
		jr $ra
	B:	
		la $v0, letterB
		addi $v1,$zero, 16
		jr $ra
	C:
		la $v0, letterC
		addi $v1,$zero, 16
		jr $ra
	D:
		la $v0, letterD
		addi $v1,$zero, 16
		jr $ra
	F:
		la $v0, letterF
		addi $v1,$zero, 16
		jr $ra
	H:
		la $v0, letterH
		addi $v1,$zero, 16
		jr $ra
	I:
		la $v0, letterI
		addi $v1,$zero, 8
		jr $ra
	J:
		la $v0, letterJ
		addi $v1,$zero, 16
		jr $ra
	K:
		la $v0, letterK
		addi $v1,$zero, 16
		jr $ra
	L:
		la $v0, letterL
		addi $v1,$zero, 16
		jr $ra
	N:
		la $v0, letterN
		addi $v1,$zero, 16
		jr $ra
	Q:
		la $v0, letterQ
		addi $v1,$zero, 16
		jr $ra
	T:
		la $v0, letterT
		addi $v1,$zero, 16
		jr $ra
	U:
		la $v0, letterU
		addi $v1,$zero, 16
		jr $ra
	V:
		la $v0, letterV
		addi $v1,$zero, 16
		jr $ra
	X:
		la $v0, letterX
		addi $v1,$zero, 16
		jr $ra
	Y:
		la $v0, letterY
		addi $v1,$zero, 16
		jr $ra
	Z:
		la $v0, letterZ
		addi $v1,$zero, 16
		jr $ra

color_index_map:
	beq $a0, 0, map_to_red
	beq $a0, 1, map_to_yellow
	beq $a0, 2, map_to_green 
	beq $a0, 3, map_to_blue

	map_to_red:
		lw $v0, red
		jr $ra
	map_to_yellow:
		lw $v0, yellow
		jr $ra
	map_to_green:
		lw $v0, green
		jr $ra
	map_to_blue:
		lw $v0, blue
		jr $ra

exit:
li $v0, 10 # terminate the program gracefully
syscall 
