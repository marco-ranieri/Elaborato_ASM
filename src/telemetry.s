.section .data


pilot_0_str:
    .string   "Pierre Gasly\0"
pilot_1_str:
    .string   "Charles Leclerc\0"
pilot_2_str:
    .string   "Max Verstappen\0"
pilot_3_str:                       
    .string   "Lando Norris\0"
pilot_4_str:
    .string   "Sebastian Vettel\0"
pilot_5_str:
    .string   "Daniel Ricciardo\0"
pilot_6_str: 
    .string   "Lance Stroll\0"
pilot_7_str:
    .string   "Carlos Sainz\0"
pilot_8_str:
    .string   "Antonio Giovinazzi\0"
pilot_9_str:
    .string   "Kevin Magnussen\0"
pilot_10_str:
    .string  "Alexander Albon\0"
pilot_11_str:
    .string  "Nicholas Latifi\0"
pilot_12_str:
    .string  "Lewis Hamilton\0"
pilot_13_str:
    .string  "Romain Grosjean\0"
pilot_14_str:
    .string  "George Russell\0"
pilot_15_str:
    .string  "Sergio Perez\0"
pilot_16_str:
    .string  "Daniil Kvyat\0"
pilot_17_str:
    .string  "Kimi Raikkonen\0"
pilot_18_str:
    .string  "Esteban Ocon\0"
pilot_19_str:
    .string  "Valtteri Bottas\0"


invalid_pilot_str:	
.string "Invalid\0"


.section .text
.global telemetry

telemetry:

pushl %eax                                      # pusho tutti i registri in sequenza sullo stack
pushl %ebx
pushl %ecx
pushl %edx


movl $0, %ecx
pilot:
    leal pilot_0_str, %esi
    movb (%esi, %ecx), %al
    incl %ecx
    cmpb $0, %al
    je fine_pilot
    jmp pilot

fine_pilot:

popl %edx                                       # poppo tutti i registri in sequenza INVERSA dallo stack
popl %ecx
popl %ebx
popl %eax

ret



# 
# movl 4(%esp), %esi                              # punto allo spazio di memoria (32bit) subito sotto nello stack e salvo l'indirizzo del primo parametro della funzione (stringa input) in %esi
# movl 8(%esp), %edi                              # stessa cosa, 2 spazi di mem sotto, 2° parametro funzione (stringa output) in %edi
# 
# pushl %eax                                      # pusho tutti i registri in sequenza sullo stack
# pushl %ebx
# pushl %ecx
# pushl %edx
# 
# xorl %ecx, %ecx                                 # azzero ecx per usarlo come contatore incrementale
# 
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
