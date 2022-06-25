.section .data

id: .long 0
invalid_pilot_str: .ascii "Invalid\n\0"

.section .text
.global telemetry

telemetry:

movl 4(%esp), %esi                              # punto allo spazio di memoria (32bit) subito sotto nello stack e salvo l'indirizzo del primo parametro della funzione (stringa input) in ESI
movl 8(%esp), %edi                              # punto allo spazio di memoria (32bit) ancora sotto nello stack e salvo l'indirizzo del secondo parametro della funzione (stringa output) in ESI

call get_pilot_id
# TODO: stmpa stringa invalid se nome pilota non valido
# (=> se passo tutti gli id pilota senza trovarlo, pilot_id sarà > 19 => metto qui la funzione per stampare la stringa invalid, non in "get_pilot_id")

xorl %eax, %eax
movl (%edi), %eax                               # salvo il pilot_id in eax
movl %eax, id                                   # lo salvo come intero nella variabile "id"

cmpl $20, id                                    # se l'id è > 20, salto alla stampa della stringa "Invalid\n\0"
jge invalid_id

# ESI continua a puntare alla stringa di input (0x5655a1a0)
# EDI continua a puntare alla stringa di output (0x5655a350)

leal id, %edi

call parse_pilot_data


ret


invalid_id:                                     # stampa stringa invalid
    xorl %ecx, %ecx
    leal invalid_pilot_str, %edx

    parse_invalid_string:
        movb (%edx, %ecx), %al
        movb %al, (%edi, %ecx)
        cmpb $0, %al
        je end
        incl %ecx
        jmp parse_invalid_string




end:
ret
