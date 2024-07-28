# ASM BMP Encryption

This repository contains an assembly language implementation for encrypting and decrypting messages embedded in BMP files. It includes two main components: a BMP encoder and a BMP decoder, both written in assembly x86 language and compiled using Clang.

## Table of Contents
- [Overview](#overview)
- [Assembling and Linking](#assembling-and-linking)
- [Usage](#usage)
- [Example Files](#example-files)
- [Creating Your Own BMP Files](#creating-your-own-bmp-files)

## Overview

- **bmp-encoder.S**: Assembly code to embed a message into a BMP file.
- **bmp-decoder.S**: Assembly code to extract a message from a BMP file.

## Assembling and Linking

To build the BMP encoder and decoder, follow these steps:

### Assembling

Run the following commands to assemble the code:

```bash
clang -c bmp-encoder.S -o bmp-encoder.o  
clang -c bmp-decoder.S -o bmp-decoder.o  
```

### Linking

Link the assembled objects to create the executables:

```bash
clang bmp-encoder.o -o bmp-encoder  
clang bmp-decoder.o -o bmp-decoder  
```

## Usage

### BMP Encoder

To embed a message into a BMP file, use from within the bmp-encoder directory:

```bash
./bmp-encoder <path-to-bmp-file> <encryption-key> <message>  
```

Example:

```bash
./bmp-encoder ../examples/test.bmp testkey testmessage
```

This command will create a new BMP file with the message embedded, using the specified encryption key.

### BMP Decoder

To extract a message from a BMP file, use from within the bmp-decoder directory:

```bash
./bmp-decoder <path-to-bmp-file> <encryption-key>
```

Example:

```bash
./bmp-decoder ../examples/test.bmp testkey
```

This command will decode the message from the BMP file using the specified encryption key.

## Example Files

Two example BMP files are provided in the `examples/` directory:

- **`test.bmp`**:
  - **Message**: `testmessage`
  - **Key**: `testkey`

- **`test2.bmp`**:
  - **Message**: `anothertestmessag`
  - **Key**: `anothertestkey`

Feel free to use these files to test the encoder and decoder. Modify or create your own BMP files as needed.

## Creating Your Own BMP Files

To create your own BMP files with encrypted messages:

1. Simply use the `bmp-encoder` to embed your message with a chosen encryption key.
2. If you want to have the BMP file look different, modify the encoder to print different colors or different patterns.
   You can do this by modifying the Bitmap loop and adding your own methods for different colors or modifying the values for switching colors.

To decode the messages, ensure you have the correct encryption key and use the `bmp-decoder` to retrieve the embedded message.
