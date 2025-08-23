    .global _start
    .text
_start:
    xor %rbp, %rbp
    call main
    mov %rax, %rdi
    mov $60, %rax
    syscall
    hlt