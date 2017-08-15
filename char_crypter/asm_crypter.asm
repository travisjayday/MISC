global _start 					; allow linker to find start symbol

%define byte_offset 0x0D		; defines the offset of ascii character distortion

section .data
	ch_byt: db 0x0
	ch_arr: times 100 db 0

section .rodata					; read only data
	in_prompt: db "(E)ncrypt? or (D)ecrypt?", 0x20, 0x0  ; space and str terminator
	str_dec: db 0xA, "decrypting: "
	str_enc: db 0xA, "encrypting: "
	str_fail: db 0xA, "input failure!", 0xA
	str_usage: db "Usage:", \
		0xA, " crypter -e string", \
		0xA, " crypter -d string", 0xA	;45 chars

section .text

_start:
	; entry procedure
	push ebp					; setup new stack frame
	mov ebp, esp				; setup new stack frame 2	

	; get arguments from the stack
	mov eax, dword [ebp+4]		; argument count
	sub eax, 0x01				; check if args is 0	
	je no_args					; if eax (arg count is 0, jump to prompt like regular program

	sub eax, 0x02				; check if two args were passed
	je with_args				; if more or less than 2 args were passed, display usage

disp_usage:
	mov eax, 0x04				; select write syscall
	mov ebx, 0x01				; select stdout
	mov ecx, str_usage			; piont ecx to in_prompt
	mov edx, 0x2D				; 45 chars 2 write
	int 0x80					; syscall

	jmp end	

with_args:
	mov eax, dword [ebp+12]		; pop first argument addr into eax
	mov dh, [eax+1]				; move the second char of argument into ecx ('e' or 'd')
	mov dl, dh					; copy al into high 8 bits of edx

	mov ebx, dword [ebp+16]		; move second argument into ebx
	push ebx					; push second argument to ebp-4 (for enc/dec procedures)
	
	; get the number of chars in the second argumennt (until null char)
count_lp: 
	mov al, byte [ebx]			; get char value at ebx
	add ebx, 0x01				; add one to next addr to get next char
	add ecx, 0x01				; inc counter
	sub al, 0x00				; prepare equal check
	jne count_lp
	
	mov byte [ebx-1], 0x0A		; replace 0x0 with newline terminator for later	

	push ecx					; how many letters will be written
	mov ecx, dword [ebp+16]				; ecx will be used to print final output, store addr of second arg

	sub dh, 0x65				; subtract 'e'	
	je write_encrypted			; go encrypting argument

	sub dl, 0x64 				; subtract ascii 'd'
	je write_decrypted			; go decrypting argument

	jmp disp_usage				; if arguments are't e or d, display usage and exit

no_args:
	; setup the stack, entry prologue
	push ebp
	mov ebp, esp

	; prompt user to select ecnrypt or decrypt
	mov eax, 0x04				; select write syscall
	mov ebx, 0x01				; select stdout
	mov ecx, in_prompt			; piont ecx to in_prompt
	mov edx, 0x1A				; 26 chars 2 write
	int 0x80					; syscall

	; pull selected character
	mov eax, 0x03				; select read syscall
	mov ebx, 0x00				; select stdin
	mov ecx, ch_byt				; point ecx to ch_byt
	mov edx, 0x02				; 2 char 2 read bec newline
	int 0x80					; syscall

	; check 'D' pressed
	mov al, [ch_byt]			; move into eax the data held in ch_byt
	sub al, 0x44				; subtract 'D' (68)
	je  decrypt

	; check 'd' pressed
	mov al, [ch_byt]			; move into eax, data of ch_byt
	sub al, 0x64				; subtract 'd' (100)	
	je decrypt

	; check 'E' pressed
	mov al, [ch_byt]			; move eax, data of ch_byt
	sub al, 0x45				; subtract 'E'
	je encrypt

	; check 'e' pressed
	mov al, [ch_byt]			; move 2 eax, data of ch_byt
	sub al, 0x65				; subtract 'e' 
	je encrypt

	; if no match found, assert input failure
	jmp in_fail

; jumped to when decrypt is selected
decrypt:
	mov eax, 0x04				; select write syscall
	mov ebx, 0x01				; select stdout
	mov ecx, str_dec			; ptr to decrypt string
	mov edx, 0x0D				; write 13 bytes
	int 0x80

	mov eax, 0x03				; select read syscall
	mov ebx, 0x00				; select stdin
	mov ecx, ch_arr				; char array pointer
	mov edx, 0x64				; read 100 chars to buffer
	int 0x80

	push ch_arr					; reference with ebp-4
	push eax					; how many bytes were read ebp-8

; dcerypts current char (where ebp-4 is pointing 2)
write_decrypted: 
	mov ebx, [ebp-4]			; move value where ebp-4 is pointing 2 into ebx (addr of current char)
	mov al, [ebx]				; A-low; least significant byte of 16bit register AX of EAX
	add al, byte_offset			; add offset of 10 to char var in eax
	mov [ebx], al				; in2 the value of the char, move the new char
	add ebx, 1					; increment address of chars
	mov [ebp-4], ebx			; mov address of next char to increment var
	sub al, byte_offset			; subtract offset from char, thus restoring original char
	sub al, 0x0A				; subtract newline from char to check if it was a newline
	jne write_decrypted			; if char does not equal 0x0, write next char 2 buffer

	sub ebx, 0x01				; go back 0 char, and corrupted newline
	mov [ebx], byte 0x0A		; override old newline with fresh one

	jmp write_output			; write output and terminates

; jumped to when encrypt is selected
encrypt:
	mov eax, 0x04				; select write syscall
	mov ebx, 0x01				; select stdout
	mov ecx, str_enc			; ptr to encript string
	mov edx, 0x0D				; write 13 bytes
	int 0x80

	mov eax, 0x03				; select read syscall
	mov ebx, 0x00				; select stdin
	mov ecx, ch_arr				; char array pointer
	mov edx, 0x64				; read 100 chars to buffer
	int 0x80

	push ch_arr					; reference with ebp-4
;	sub eax, 1					; remove newline char
	push eax					; how many bytes were read ebp-8

; encrypts current var (where ebp-4 is pointing 2)
write_encrypted: 
	mov ebx, [ebp-4]			; move value where ebp-4 is pointing 2 into ebx (addr of current char)
	mov al, [ebx]				; A-low; least significant byte of 16bit register AX of EAX
	sub al, byte_offset			; add offset of 10 to char var in eax
	mov [ebx], al				; in2 the value of the char, move the new char
	add ebx, 1					; increment address of chars
	mov [ebp-4], ebx			; mov address of next char to increment var
	add al, byte_offset			; subtract offset from char, thus restoring original char
	sub al, 0x0A				; subtract newline from char to check if it was a newline
	jne write_encrypted			; if char does not equal 0x0, write next char 2 buffer

	sub ebx, 0x01				; go back 0 char, and corrupted newline
	mov [ebx], byte 0x0A		; override old newline with fresh one

	jmp write_output			; write output & terminate

write_output:
	pop eax						; pop number of bytes to write (determined from read bytes)
	mov edx, eax				; write eax bytes
	mov eax, 0x04				; select write syscall
	mov ebx, 0x01				; select stdout
;	mov ecx, ch_arr				; ptr to encript string
	int 0x80

	jmp end

; jumped to on unexpected input
in_fail: 
	mov eax, 0x04				; select write syscall
	mov ebx, 0x01				; select stdout
	mov ecx, str_fail			; ptr to encript string
	mov edx, 0x10				; write 16 bytes
	int 0x80
		
	jmp end						; terminate

end:
	mov eax, 0x01				; terminate syscall
	mov ebx, 0					; return code
	int 0x80
