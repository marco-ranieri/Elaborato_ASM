.section .data

id: .long 0

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

# ESI continua a puntare alla stringa di input (0x5655a1a0)
# EDI continua a puntare alla stringa di output (0x5655a350)

leal id, %edi

call parse_pilot_data


ret



# ciclo:
# 
#     movb (%esi, %ecx), %al                      # prendo il primo carattere della stringa di input e lo metto in al
#     movb %al, (%edi, %ecx)                      # lo metto da %al al primo posto nella stringa di output
#     incl %ecx                                   # incremento ecx per passare all aprossima lettera al ciclo successivo
#     cmpb $0, %al                                # confronto il carattere che ho in %al con il valore 0 (fine stringa)
#     je fine
# jmp ciclo                                       # se non è 0, ricomincio il ciclo (passando alla lettera successiva)
# 
# 
# fine:                                            
# popl %edx                                       # poppo tutti i registri in sequenza INVERSA dallo stack
# popl %ecx
# popl %ebx
# popl %eax
# 
# ret
