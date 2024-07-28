#ifdef MACOS
    .global _bmp_decode
    .global _main
    printf: jmp _printf
    malloc: jmp _malloc
    calloc: jmp _calloc
    realloc: jmp _realloc
    free: jmp _free
    fopen: jmp _fopen
    fread: jmp _fread
    fwrite: jmp _fwrite
    fclose: jmp _fclose
    strcpy: jmp _strcpy
    strlen: jmp _strlen
    strncpy: jmp _strncpy
    strnlen: jmp _strnlen
#else 
    .global bmp_decode
    .global main
    _printf: jmp printf
    _malloc: jmp malloc
    _calloc: jmp calloc
    _realloc: jmp realloc
    _free: jmp free
    _fopen: jmp fopen
    _fread: jmp fread
    _fwrite: jmp fwrite
    _fclose: jmp fclose
    _strcpy: jmp strcpy
    _strlen: jmp strlen
    _strncpy: jmp strncpy
    _strnlen: jmp strnlen
#endif

.bss

.data
key:
    .quad 0
file:
    .quad 0
buffer:
    .skip 451
buffer2:
    .skip 5000
buffer3:
    .skip 440
buffer4:
    .skip 5000
buffer5:
    .skip 5000

.text
r:
    .asciz "r"

_main:
main:
    pushq   %rbp
    movq    %rsp, %rbp

    addq    $8, %rsi
    movq    (%rsi), %rdi                # Move pointer to file path in first argument to variable
    movq    %rdi, file(%rip)
    addq    $8, %rsi                    # Go to the next pointed at
    movq    (%rsi), %rdi                # Move pointer to key to the variable
    movq    %rdi, key(%rip)

    movq    file(%rip), %rdi
    leaq    r(%rip), %rsi
    call    fopen
    movq    %rax, file(%rip)            # Update pointer to file

    leaq    buffer(%rip), %rdi
    movq    key(%rip), %rsi
    movq    file(%rip), %rdx
    call    bmp_decode

    movq    $0, %rax
    movq    %rbp, %rsp
    popq    %rbp
    ret

# int bmp_decode(char *buf, const char *key, FILE* file)
_bmp_decode:
bmp_decode:
    pushq   %rbp
    movq    %rsp, %rbp

    subq    $64, %rsp

    movq    %rdi, -56(%rbp)             # Pointer to buffer
    movq    %rsi, -16(%rbp)             # Pointer to key
    movq    %rdx, -24(%rbp)             # Pointer to file

    leaq    buffer2(%rip), %rdi
    movq    $4150, %rsi
    movq    $1, %rdx
    movq    -24(%rbp), %rcx
    call    fread
    leaq    buffer2(%rip), %rdi
    addq    $3126, %rdi
    movq    %rdi, -40(%rbp)

RepeatKey:
    movq    -16(%rbp), %rsi             # The pointer to beginning of key into rsi
XORloop:
    movq    (%rdi), %rax
    cmpq    $0, %rax                    # Check if the end has been reached for the message
    je      RLE                         # If so start writing into the file
    movb    (%rdi), %al
    movb    (%rsi), %dl
    cmpb    $0, %dl                     # Check if the end has been reached for the key
    je      RepeatKey                   # If so we repeat the key
    xorb    %dl, %al                    # Value of the byte updates to the result of xor operation
    movb    %al, (%rdi)                 # Update the encoded message
    incq    %rsi                        # Next character
    incq    %rdi                        # Next character
    jmp     XORloop                     # Repeat the process

RLE:
    movq    -40(%rbp), %rdi
    leaq    buffer4(%rip), %rsi
    decq    %rdi
RLELoop:
    incq    %rdi
    movb    (%rdi), %al
    subb    $48, %al
    incq    %rdi
RLELoop2:
    movb    (%rdi), %dl
    cmpb    $0, %dl
    je      Epilogue
    cmpb    $0, %al
    jle     RLELoop
    movb    %dl, (%rsi)
    incq    %rsi
    decb    %al
    jmp     RLELoop2 

Epilogue:  
    movb    $0, (%rsi)
    leaq    buffer4(%rip), %rdi
    call    strlen
    movq    %rax, %rcx
    leaq    buffer4(%rip), %rdi
    leaq    buffer3(%rip), %rsi
loopepi:
    cmpq    $0, %rcx
    jle     exitloop
    movb    (%rdi), %al
    movb    %al, (%rsi)
    incq    %rdi
    incq    %rsi
    decq    %rcx
    jmp     loopepi
exitloop:
    leaq    buffer3(%rip), %rsi
    leaq    buffer5(%rip), %rdi
    movq    $440, %rdx
    call    strncpy

    movq    %rax, -56(%rbp)
    movq    -56(%rbp), %rdi

    movq    -56(%rbp), %rdi
    movq    %rax, %rsi
    call    strcpy
    
    movb    $0, %al
    call    printf   

    movq    $0, %rax
    movq    %rbp, %rsp
    popq    %rbp
    ret
