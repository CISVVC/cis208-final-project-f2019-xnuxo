; Name: asm_main.asm
; Developer: Jude McParland
; Date: 12-13-19
; Email: judem6968@student.vvc.edu
; Description: A program that displays usage (and knowledge) of allocating and passing arrays on the stack. Uses arr1 as base.

%include    "asm_io.inc" 
%define     NEW_LINE 10

; Initialized (Variables) Data
segment .data
arr1    dd      180,32,455,499,388,480,239,346,257,84
Msg1    dd      "The first array (180,32,455,499,388,480,239,346,257,84) is initialized on the .data segment.", 0
Msg2    dd      "Adding 10 to each position in ARR1 (first array) results in the second array as follows: ", 0
Msg3    dd      "Multiplying 10 to each position in ARR1 results in the third array as follows: ", 0 
Msg4    dd      "Merging the first array (ARR1) and third array (ARR3) into one by addition results in the fourth array as follows: "

; Uninitialized (No-Value Variables) Data
segment .bss
arr3    resd    10

segment .text
        global  asm_main
        extern  printf
asm_main:
        enter   0,0                 ; setup routine
        pusha
;
;   EXCUSE THE FORMATTING STUFF // FOCUS ON _step_one, _step_two, _step_three calls!
;
        mov     eax, Msg1           ; Print first message (tells user I have alloc'd the first array)
        call    print_string
        call    print_nl
        call    print_nl

        push    dword 10            ; N (size of array)
        push    dword arr1          ; addr of array

        mov     eax, Msg2           ; Print second message (Add 10)
        call    print_string
        call    print_nl
        call    _step_one           
        call    print_nl
        
        mov     eax, Msg3           ; Print third message (Mul 10)
        call    print_string
        call    print_nl
        call    _step_two
        call    print_nl

        mov     eax, Msg4           ; Print fourth message 
        call    print_string        ; (Arr4[i]=Arr1[i]+Arr3[i])
        call    print_nl
        call    _step_three
        call    print_nl

        add     esp, 8              ; Clear stack of N and arr1 addr (ln 31, 32).
;
        popa
        mov     eax, 0              ; return back to C
        leave                     
        ret

; Routine: Step One
; EBP+12 = N of array
; EBP+8  = Addr of array
; Allocs a local array block of 10 dwords (40 bytes) on the stack.
; Takes arr1 and stores the computation (+10) on local alloc array for printing.
segment .text
        global  _step_one
_step_one:
        enter   40, 0               ; Alloc 40 bytes ([EBP-4] to [EBP-4*10]), 10 DWORD array
        push    esi
        push    ebx
        
        mov     ecx, [ebp+12]       ; N
        mov     ebx, [ebp+8]        ; arr1 addr
        xor     esi, esi            ; esi = 0

    loop1:
        mov     eax, [ebx+4*esi]    ; eax = arr1[esi]
        add     eax, 10             ; eax += 10
        mov     [esp+4*esi+8], eax    ; Store eax into local array[esi]
        inc     esi
        loop    loop1

        lea     ebx, [ebp-40]       ; load addr of local array for _print_array
        push    dword 10            ; push size
        push    ebx                 ; Push local Array ADDR
        call    _print_array
        add     esp, 8
        pop     ebx
        pop     esi
        leave
        ret

; Routine: Step Two
; EBP+12 = N of array
; EBP+8  = Addr of array
; Populates arr3 on .bss (remember arr2 was locally printed). 
; Takes arr1 and stores the computation (*10) on bss allocated array for printing/storage.
segment .text
        global  _step_two
_step_two:
        enter   0,0
        push    esi
        push    ebx
        push    edx                 ; 32bit array in .bss, Imma be simple and use edx tbh. I aint a compiler XD 

        mov     ecx, [ebp+12]       ; N
        mov     ebx, [ebp+8]        ; arr1 addr
        mov     edx, arr3           ; edx = Starting Addr of arr3
        xor     esi, esi            ; esi = 0

    loop2:
        mov     eax, [ebx+4*esi]    ; eax = arr1[esi]
        imul    eax, 10             ; eax *= 10
        mov     [edx+4*esi], eax    ; arr3[esi] = eax
        inc     esi
        loop    loop2

        push    dword 10
        push    edx
        call    _print_array
        add     esp, 8
        pop     edx
        pop     ebx
        pop     esi
        leave
        ret

; Routine: Step Three
; EBP+12 = N of array
; EBP+8  = Addr of array
; EBX = arr1 addr
; EDX = arr3 addr
; Adds first array to third and prints out. NO STORAGE (uses local array for printing).
segment .text
        global  _step_three
_step_three:
        enter   40, 0                ; OPEN THE GATE FOR THEE DATA! (10 DWORDS)
        push    esi
        push    ebx
        push    edx   

        mov     ecx, [ebp+12]       ; N
        mov     ebx, [ebp+8]        ; arr1 addr
        mov     edx, arr3           ; arr3 addr
        xor     esi, esi            

    loop3:
        mov     eax, [ebx+4*esi]    ; eax = arr1[esi]
        add     eax, [edx+4*esi]    ; eax = arr1[esi] + arr3[esi]
        mov     [esp+4*esi+12], eax  ; Store eax into local array[esi] (+12 because esi,ebx,edx push)
        inc     esi
        loop    loop3

        lea     ebx, [ebp-40]       ; load addr of local array for _print_array
        push    dword 10            ; push size
        push    ebx                 ; Push local Array ADDR
        call    _print_array
        add     esp, 8
        pop     edx
        pop     ebx
        pop     esi
        leave
        ret

;######################################################################################################
; SOURCE: PAUL CARTER ASM! THIS IS NOT MY OWN CODE BUT AS WE USE asm_main.io FXNS I ASSUME THIS IS FINE
;######################################################################################################
; Note: Besides, I would've copied this technique anyway, it's my learning example.
;
; routine print_array
; C-callable routine that prints out elements of a double word array as
; signed integers.
; C prototype:
; void print_array( const int * a, int n);
; Parameters:
;   a - pointer to array to print out (at ebp+8 on stack)
;   n - number of integers to print out (at ebp+12 on stack)

segment .data
OutputFormat    db   "%-5d %5d", NEW_LINE, 0

segment .text
        global  _print_array
_print_array:
        enter   0,0
        push    esi
        push    ebx

        xor     esi, esi                  ; esi = 0
        mov     ecx, [ebp+12]             ; ecx = n
        mov     ebx, [ebp+8]              ; ebx = address of array
print_loop:
        push    ecx                       ; printf might change ecx!

        push    dword [ebx + 4*esi]       ; push array[esi]
        push    esi
        push    dword OutputFormat
        call    printf
        add     esp, 12                   ; remove parameters (leave ecx!)

        inc     esi
        pop     ecx
        loop    print_loop

        pop     ebx
        pop     esi
        leave
        ret
