#ifdef MACOS
    .global _bmp_encode
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
    .global bmp_encode
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
msg:
    .quad 0
key:
    .quad 0
file:
    .quad 0
pixeldata:
    .skip 3072

.text
wb:
    .asciz "wb"

# usage: ./bmp-encoder destination(.bmp) key msg
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
    addq    $8, %rsi                    # Go to the next pointed at
    movq    (%rsi), %rdi                # Move pointer to message to variable
    movq    %rdi, msg(%rip)

    movq    file(%rip), %rdi
    leaq    wb(%rip), %rsi              # Writing mode in binary
    call    fopen                       # Open file
    movq    %rax, file(%rip)            # Update pointer to file

    movq    %rax, %rdx
    movq    key(%rip), %rsi
    movq    msg(%rip), %rdi
    call    bmp_encode

    movq    file(%rip), %rdi
    call    fclose

    movq    $0, %rax
    movq    %rbp, %rsp
    popq    %rbp    
    ret

# int bmp_encode(const char *msg, const char *key, FILE* file)
_bmp_encode:
bmp_encode:
    # -8 contains pointer to message
    # -16 contains pointer to key
    # -24 contains a pointer to the encoded message
    # -32 contains a pointer to the pixel data
    # -40 contains pointer to the file in stack

    pushq   %rbp
    movq    %rsp, %rbp

    subq    $64, %rsp                   # Reserve space
    movq    %rdi, -8(%rbp)              # Save the pointer to message in stack
    movq    %rsi, -16(%rbp)             # Same with key
    movq    %rdx, -40(%rbp)             # And the pointer to the file in stack

    movq    $1024, %rdi
    call    malloc
    movq    %rax, -24(%rbp)             # Store buffer in stack
    movq    %rax, %rcx

    # First we do run length encoding
    movq    -8(%rbp), %rdi
    movb    (%rdi), %al                 # Character to al
    movq    $1, %r8                     # Counter to 1
RLE:
    incq    %rdi                        # Move to next character
    movb    (%rdi), %dl                 # Next character to dl
    cmpb    $0, %al                     # Check if message has ended
    je      XORbegin                    # If so go to XOR
    cmpb    %al, %dl                    # Compare
    je      Equal                       # If they're equal jump to equal
NEqual:
    addq    $48, %r8                    # Convert to ascii value
    movq    %r8, (%rcx)                 # Move the amount/counter to the array
    incq    %rcx                        # Next index
    movb    %al, (%rcx)                 # Move the character to array
    incq    %rcx                        # Next index
    movq    $1, %r8                     # Reset counter
RLE2:
    movb    %dl, %al                    # Set this character to al
    jmp     RLE                         # Repeat the loop
Equal:
    incq    %r8                         # Increase counter
    cmpq    $9, %r8                     # Check if r8 has reached the ninth
    je      NEqual                      # In that case we still print and reset
    jne     RLE2                        # Otherwise we loop

XORbegin: 
    movq    -24(%rbp), %rdi             # The pointer to encoded message into rdi
RepeatKey:
    movq    -16(%rbp), %rsi             # The pointer to beginning of key into rsi
XORloop:
    movb    (%rdi), %al
    cmpb    $0, %al                     # Check if the end has been reached for the message
    je      BitmapPrologue              # If so start writing into the file
    movb    (%rsi), %dl
    cmpb    $0, %dl                     # Check if the end has been reached for the key
    je      RepeatKey                   # If so we repeat the key
    xorb    %dl, %al                    # Value of the byte updates to the result of xor operation
    movb    %al, (%rdi)                 # Update the encoded message
    incq    %rsi                        # Next character
    incq    %rdi                        # Next character
    jmp     XORloop                     # Repeat the process

BitmapPrologue:
    movq    -24(%rbp), %rdi             # The pointer to encoded message into rdi 
    movq    $14, %rdi
    call    malloc                      # Create file header
    push    %rax
    movb    $66, (%rax)
    movb    $77, 1(%rax)
    movl    $3126, 2(%rax)              # File size: 14 + 40 + 3072
    movl    $0, 6(%rax)                 # Reserved field: 0
    movl    $0, 10(%rax)                # Offset of pixel data: 0
    movq    %rax, %rdi
    movq    $1, %rsi
    movq    $14, %rdx
    movq    -40(%rbp), %rcx
    call    fwrite                      # Write fileheader onto file
    pop     %rdi
    call    free
    
    movq    $40, %rdi
    call    malloc                      # Create bitmap header
    push    %rax
    movl    $40, (%rax)                 # Header size
    movl    $32, 4(%rax)                # Width
    movl    $32, 8(%rax)                # Height
    movw    $1, 12(%rax)                # 2 bytes of reserved field
    movw    $24, 14(%rax)               # Number of bits per pixel
    movl    $0, 16(%rax)                # Compression method 0
    movl    $3072, 20(%rax)             # Size of pixel data
    movl    $2835, 24(%rax)             # Horizontal resolution
    movl    $2835, 28(%rax)             # Vertical resolution
    movl    $0, 32(%rax)                # Colour palette information
    movl    $0, 36(%rax)                # number of important colors
    movq    %rax, %rdi
    movq    $1, %rsi
    movq    $40, %rdx
    movq    -40(%rbp), %rcx             # Pointer to file stream
    call    fwrite                      # Write bitmap header onto file
    pop     %rdi
    call    free

    movq    $3072, %rdi
    call    malloc                      # Create buffer for the pixels
    movq    %rax, -32(%rbp)             # Store in stack
    movq    %rax, %rdi                  # Pointer also in rdi
    movq    $0, %rcx                    # Set pixel counter to 0
    movq    $0, %r8                     # Set column counter to 1

Bitmaploop:
    cmpq    $3072, %rcx
    jge     BitmapEpilogue
    cmpq    $8, %r8
    jl      White
    cmpq    $16, %r8
    jl      Black
    cmpq    $20, %r8
    jl      White
    cmpq    $24, %r8
    jl      Black
    cmpq    $26, %r8
    jl      White
    cmpq    $29, %r8
    jl      Black
    cmpq    $31, %r8
    jl      White
    movq    $0, %r8

Red:
    movb    $0, (%rdi)                  # Blue value
    incq    %rdi
    movb    $0, (%rdi)                  # Green value
    incq    %rdi
    movb    $255, (%rdi)                # Red value
    incq    %rdi
    addq    $3, %rcx
    jmp     Bitmaploop

White:
    movb    $255, (%rdi)                # Blue value
    incq    %rdi
    movb    $255, (%rdi)                # Green value
    incq    %rdi
    movb    $255, (%rdi)                # Red value
    incq    %rdi
    addq    $3, %rcx
    addq    $1, %r8
    jmp     Bitmaploop

Black:
    movb    $0, (%rdi)                  # Blue value
    incq    %rdi
    movb    $0, (%rdi)                  # Green value
    incq    %rdi
    movb    $0, (%rdi)                  # Red value
    incq    %rdi
    addq    $3, %rcx
    addq    $1, %r8
    jmp     Bitmaploop

BitmapEpilogue:
    movq    -32(%rbp), %rdi             # Write pixel data
    movq    $1, %rsi
    movq    $3072, %rdx
    movq    -40(%rbp), %rcx
    call    fwrite
    movq    -24(%rbp), %rdi             # Encoded Message
    movq    $1, %rsi
    movq    $1024, %RDX
    movq    -40(%rbp), %rcx
    call    fwrite 

    jmp     Epilogue

Epilogue:
    movq    $0, %rax
    movq    %rbp, %rsp
    popq    %rbp
    ret
