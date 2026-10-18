; kernel.asm - XOS 1.0 (Invisible Page Bug Fix!)
[org 0x1000]
[bits 16]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00      
    sti

    mov ah, 0x00
    int 0x1A
    mov [rand_seed], dx

    mov byte [current_color], 0x1F  
    call clear_screen
    mov si, welcome_msg
    call print_string

shell_loop:
    call force_color        
    mov si, prompt
    call print_string
    
    mov di, input_buffer
    call read_string

    mov si, input_buffer
    
    mov di, cmd_help
    call strcmp
    jc do_help

    mov di, cmd_clear
    call strcmp
    jc do_clear

    mov di, cmd_calc
    call strcmp
    jc do_calc

    mov di, cmd_logo
    call strcmp
    jc do_logo

    mov di, cmd_color
    call strcmp
    jc do_color

    mov di, cmd_game
    call strcmp
    jc do_game

    mov di, cmd_ver
    call strcmp
    jc do_ver

    mov di, cmd_time
    call strcmp
    jc do_time

    mov di, cmd_reboot
    call strcmp
    jc do_reboot

    cmp byte [input_buffer], 0
    je shell_loop

    mov si, unknown_msg
    call print_string
    jmp shell_loop

; =========================================
; 명령어 실행 로직
; =========================================
do_help:
    mov si, help_text
    call print_string
    jmp shell_loop

do_clear:
    call clear_screen
    jmp shell_loop

do_logo:
    mov si, logo_art
    call print_string
    jmp shell_loop

do_color:
    mov si, color_menu
    call print_string
.wait_key:
    mov ah, 0x00
    int 0x16                
    cmp al, '1'
    je .theme_black
    cmp al, '2'
    je .theme_blue
    cmp al, '3'
    je .theme_matrix
    cmp al, '4'
    je .theme_red
    jmp .wait_key           
.theme_black:
    mov byte [current_color], 0x07
    jmp .apply
.theme_blue:
    mov byte [current_color], 0x1F
    jmp .apply
.theme_matrix:
    mov byte [current_color], 0x0A
    jmp .apply
.theme_red:
    mov byte [current_color], 0x4F
    jmp .apply
.apply:
    mov ah, 0x0E
    mov bx, 0x000F          ; ★ BH=0 (0번 페이지 지정)
    int 0x10
    mov si, newline
    call print_string
    call clear_screen       
    jmp shell_loop

do_ver:
    mov si, ver_msg
    call print_string
    jmp shell_loop

do_reboot:
    mov si, reboot_msg
    call print_string
    jmp 0xFFFF:0x0000

do_time:
    mov ah, 0x02
    int 0x1A
    mov si, time_msg
    call print_string
    mov al, ch
    call print_hex_bcd
    mov al, ':'
    mov ah, 0x0E
    mov bx, 0x000F
    int 0x10
    mov al, cl
    call print_hex_bcd
    mov al, ':'
    mov ah, 0x0E
    mov bx, 0x000F
    int 0x10
    mov al, dh
    call print_hex_bcd
    mov si, newline
    call print_string
    jmp shell_loop

; =========================================
; XOS 미니게임 천국
; =========================================
do_game:
    mov si, game_menu
    call print_string
.wait_game:
    mov ah, 0x00
    int 0x16
    cmp al, '1'
    je game_guess
    cmp al, '2'
    je game_rps
    cmp al, '3'
    je game_slot
    cmp al, '4'
    je game_dice
    cmp al, '5'
    je game_math
    jmp .wait_game

game_guess:
    mov si, newline
    call print_string
    mov si, msg_g1_intro
    call print_string
    mov cx, 100
    call rand
    mov [secret_num], al
.g1_loop:
    mov si, msg_g1_prompt
    call print_string
    mov di, input_buffer
    call read_string
    call atoi
    cmp al, [secret_num]
    je .win
    jl .higher
    jmp .lower
.higher:
    mov si, msg_higher
    call print_string
    jmp .g1_loop
.lower:
    mov si, msg_lower
    call print_string
    jmp .g1_loop
.win:
    mov si, msg_win
    call print_string
    jmp shell_loop

game_rps:
    mov si, newline
    call print_string
    mov si, msg_g2_intro
    call print_string
    mov di, input_buffer
    call read_string
    call atoi
    cmp al, 1
    jl shell_loop
    cmp al, 3
    jg shell_loop
    mov bl, al
    mov cx, 3
    call rand
    inc al
    mov cl, al
    mov si, msg_comp_choice
    call print_string
    mov al, cl
    call print_num
    mov si, newline
    call print_string
    cmp bl, cl
    je .tie
    cmp bl, 1
    je .u_rock
    cmp bl, 2
    je .u_paper
    cmp cl, 2
    je .win
    jmp .lose
.u_rock:
    cmp cl, 3
    je .win
    jmp .lose
.u_paper:
    cmp cl, 1
    je .win
    jmp .lose
.win:
    mov si, msg_win
    call print_string
    jmp shell_loop
.lose:
    mov si, msg_lose
    call print_string
    jmp shell_loop
.tie:
    mov si, msg_tie
    call print_string
    jmp shell_loop

game_slot:
    mov si, newline
    call print_string
    mov si, msg_g3_intro
    call print_string
    mov cx, 7
    call rand
    mov bl, al
    call rand
    mov bh, al
    call rand
    mov dl, al
    mov si, msg_g3_slot1
    call print_string
    mov al, bl
    call print_num
    mov si, msg_g3_slot2
    call print_string
    mov al, bh
    call print_num
    mov si, msg_g3_slot2
    call print_string
    mov al, dl
    call print_num
    mov si, msg_g3_slot3
    call print_string
    cmp bl, bh
    jne .lose
    cmp bh, dl
    jne .lose
    mov si, msg_win
    call print_string
    jmp shell_loop
.lose:
    mov si, msg_lose
    call print_string
    jmp shell_loop

game_dice:
    mov si, newline
    call print_string
    mov si, msg_g4_intro
    call print_string
    
    mov cx, 6
    call rand
    inc al
    mov bl, al
    mov cx, 6
    call rand
    inc al
    add bl, al
    
    mov cx, 6
    call rand
    inc al
    mov bh, al
    mov cx, 6
    call rand
    inc al
    add bh, al
    
    mov si, msg_g4_comp
    call print_string
    mov al, bl
    call print_num
    mov si, newline
    call print_string
    mov si, msg_g4_user
    call print_string
    mov al, bh
    call print_num
    mov si, newline
    call print_string
    
    cmp bh, bl
    je .tie
    jg .win
    jmp .lose
.win:
    mov si, msg_win
    call print_string
    jmp shell_loop
.lose:
    mov si, msg_lose
    call print_string
    jmp shell_loop
.tie:
    mov si, msg_tie
    call print_string
    jmp shell_loop

game_math:
    mov si, newline
    call print_string
    mov cx, 50
    call rand
    mov bl, al
    mov cx, 50
    call rand
    mov bh, al
    mov si, msg_g5_intro
    call print_string
    mov al, bl
    call print_num
    mov si, msg_g5_plus
    call print_string
    mov al, bh
    call print_num
    mov si, msg_g5_eq
    call print_string
    mov di, input_buffer
    call read_string
    call atoi
    add bl, bh
    cmp al, bl
    je .win
    jmp .lose
.win:
    mov si, msg_win
    call print_string
    jmp shell_loop
.lose:
    mov si, msg_lose
    call print_string
    jmp shell_loop

; =========================================
; 유틸리티 함수 모음
; =========================================
rand:
    push dx
    push bx
    mov ax, [rand_seed]
    mov bx, 25173
    mul bx
    add ax, 13849
    mov [rand_seed], ax
    xor dx, dx
    div cx
    mov ax, dx
    pop bx
    pop dx
    ret
rand_seed dw 0x1234

atoi:
    push bx
    push cx
    push si
    xor ax, ax
    mov si, input_buffer
.loop:
    mov cl, [si]
    cmp cl, 0
    je .done
    cmp cl, '0'
    jl .done
    cmp cl, '9'
    jg .done
    sub cl, '0'
    mov bl, 10
    mul bl
    add al, cl
    inc si
    jmp .loop
.done:
    pop si
    pop cx
    pop bx
    ret

; ★ [버그 해결!] 출력 시 페이지 번호(BH)가 꼬이지 않도록 완벽 차단
print_num:
    pusha
    aam
    mov cx, ax          ; BH 대신 CX에 자릿수 임시 보관 (CH=십의자리, CL=일의자리)
    mov ah, 0x0E
    mov bx, 0x000F      ; 항상 0번 페이지로 강제 지정!
    cmp ch, 0
    je .skip_tens
    mov al, ch
    add al, '0'
    int 0x10
.skip_tens:
    mov al, cl
    add al, '0'
    int 0x10
    popa
    ret

print_hex_bcd:
    pusha
    mov cl, al          
    shr al, 4           
    add al, '0'
    mov bx, 0x000F      ; 0번 페이지 지정
    mov ah, 0x0E
    int 0x10
    
    mov al, cl          
    and al, 0x0F        
    add al, '0'
    mov bx, 0x000F      ; 0번 페이지 지정
    mov ah, 0x0E
    int 0x10
    popa
    ret

do_calc:
    mov si, calc_msg1
    call print_string
    mov di, input_buffer
    call read_string
    call atoi
    mov bl, al
    
    mov si, calc_msg2
    call print_string
    mov di, input_buffer
    call read_string
    call atoi
    add bl, al
    
    mov si, calc_result
    call print_string
    mov al, bl
    call print_num
    mov si, newline
    call print_string
    jmp shell_loop

; ★ [버그 해결!] 화면에 글을 쓸 때는 반드시 0번 페이지(BH=0)에 쓰도록 수정
print_string:
    push bx
    push ax
    mov bx, 0x000F      ; 항상 0번 페이지(BH=0)로 강제 지정!
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    pop ax
    pop bx
    call force_color
    ret

read_string:
    mov cx, 0
.read_loop:
    mov ah, 0x00
    int 0x16
    cmp al, 0x0D
    je .enter_pressed
    cmp al, 0x08
    je .backspace_pressed
    cmp cx, 63
    jge .read_loop
    stosb
    inc cx
    mov bx, 0x000F      ; 0번 페이지 지정
    mov ah, 0x0E
    int 0x10
    call force_color
    jmp .read_loop
.backspace_pressed:
    cmp cx, 0
    je .read_loop
    dec di
    dec cx
    mov bx, 0x000F      ; 0번 페이지 지정
    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    call force_color
    jmp .read_loop
.enter_pressed:
    mov al, 0
    stosb
    mov si, newline
    call print_string
    ret

strcmp:
    push si
    push di
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .not_equal
    cmp al, 0
    je .equal
    inc si
    inc di
    jmp .loop
.equal:
    pop di
    pop si
    stc
    ret
.not_equal:
    pop di
    pop si
    clc
    ret

clear_screen:
    mov ah, 0x06
    mov al, 0
    mov bh, [current_color]
    mov cx, 0
    mov dx, 0x184F
    int 0x10
    mov ah, 0x02
    mov bh, 0
    mov dx, 0
    int 0x10
    ret

force_color:
    pusha
    push es
    mov ax, 0xB800      
    mov es, ax
    mov cx, 2000        
    mov di, 1           
    mov al, [current_color]
.loop:
    mov [es:di], al     
    add di, 2           
    loop .loop
    pop es
    popa
    ret

; =========================================
; 데이터 영역 
; =========================================
current_color db 0x1F

welcome_msg db '=== XOS 1.0 OFFICIAL RELEASE ===', 13, 10, 13, 10, 0
prompt      db 'XOS> ', 0
newline     db 13, 10, 0
unknown_msg db 'Bad command. Type "help".', 13, 10, 0

help_text   db 'Available Commands:', 13, 10
            db ' - help  : Show this message', 13, 10
            db ' - ver   : Show OS version', 13, 10
            db ' - time  : Show current time', 13, 10
            db ' - clear : Clear screen', 13, 10
            db ' - color : Change OS theme', 13, 10
            db ' - logo  : Display Logo', 13, 10
            db ' - calc  : Run Calculator', 13, 10
            db ' - game  : Launch XOS Arcade', 13, 10
            db ' - reboot: Restart system', 13, 10, 0

ver_msg     db 'XOS Version 1.0 (Final Build)', 13, 10, 0
reboot_msg  db 'Rebooting system...', 13, 10, 0
time_msg    db 'Current Time: ', 0

color_menu  db 'Select OS Color Theme:', 13, 10
            db ' 1. Classic Black', 13, 10
            db ' 2. Original Blue', 13, 10
            db ' 3. Matrix Green', 13, 10
            db ' 4. Alert Red', 13, 10
            db 'Select (1-4): ', 0

logo_art    db '  __  __  ___  ____  ', 13, 10
            db '  \ \/ / / _ \/ ___| ', 13, 10
            db '   \  / | | | \___ \ ', 13, 10
            db '   /  \ | |_| |___) |', 13, 10
            db '  /_/\_\ \___/|____/ ', 13, 10, 13, 10, 0

calc_msg1   db 'First number (0-99): ', 0
calc_msg2   db 'Second number (0-99): ', 0
calc_result db 'Result: ', 0

game_menu   db '=== XOS ARCADE ===', 13, 10
            db ' 1. Number Guess (0-99)', 13, 10
            db ' 2. Rock Paper Scissors', 13, 10
            db ' 3. Slot Machine', 13, 10
            db ' 4. Dice Roll', 13, 10
            db ' 5. Math Quiz', 13, 10
            db 'Select Game (1-5): ', 0

msg_win     db ' -> YOU WIN!', 13, 10, 0
msg_lose    db ' -> YOU LOSE...', 13, 10, 0
msg_tie     db ' -> IT IS A TIE!', 13, 10, 0

msg_g1_intro  db 'Guess the secret number (0-99)!', 13, 10, 0
msg_g1_prompt db 'Your guess: ', 0
msg_higher    db ' -> HIGHER!', 13, 10, 0
msg_lower     db ' -> LOWER!', 13, 10, 0
secret_num    db 0

msg_g2_intro    db '1.Rock  2.Paper  3.Scissors : ', 0
msg_comp_choice db 'Computer chose: ', 0

msg_g3_intro  db 'Pulling Slot Machine Lever...', 13, 10, 0
msg_g3_slot1  db '[ ', 0
msg_g3_slot2  db ' | ', 0
msg_g3_slot3  db ' ]', 13, 10, 0

msg_g4_intro  db 'Rolling 2 dice for each...', 13, 10, 0
msg_g4_comp   db 'Computer total: ', 0
msg_g4_user   db 'Your total: ', 0

msg_g5_intro  db 'Solve: ', 0
msg_g5_plus   db ' + ', 0
msg_g5_eq     db ' = ? ', 0

cmd_help   db 'help', 0
cmd_ver    db 'ver', 0
cmd_time   db 'time', 0
cmd_clear  db 'clear', 0
cmd_color  db 'color', 0
cmd_logo   db 'logo', 0
cmd_calc   db 'calc', 0
cmd_game   db 'game', 0
cmd_reboot db 'reboot', 0

input_buffer times 64 db 0

times 1474048-($-$$) db 0