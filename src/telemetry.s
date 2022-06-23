.section .data


pilot_0_str:    .string     "Pierre Gasly\0"        # 13
pilot_1_str:    .string     "Charles Leclerc\0"     # 16
pilot_2_str:    .string     "Max Verstappen\0"      # 15
pilot_3_str:    .string     "Lando Norris\0"        # 13
pilot_4_str:    .string     "Sebastian Vettel\0"    # 17
pilot_5_str:    .string     "Daniel Ricciardo\0"    # 17
pilot_6_str:    .string     "Lance Stroll\0"        # 13
pilot_7_str:    .string     "Carlos Sainz\0"        # 13
pilot_8_str:    .string     "Antonio Giovinazzi\0"  # 19
pilot_9_str:    .string     "Kevin Magnussen\0"     # 16
pilot_10_str:   .string     "Alexander Albon\0"     # 16
pilot_11_str:   .string     "Nicholas Latifi\0"     # 16
pilot_12_str:   .string     "Lewis Hamilton\0"      # 15
pilot_13_str:   .string     "Romain Grosjean\0"     # 16
pilot_14_str:   .string     "George Russell\0"      # 15
pilot_15_str:   .string     "Sergio Perez\0"        # 13
pilot_16_str:   .string     "Daniil Kvyat\0"        # 13
pilot_17_str:   .string     "Kimi Raikkonen\0"      # 15
pilot_18_str:   .string     "Esteban Ocon\0"        # 13
pilot_19_str:   .string     "Valtteri Bottas\0"     # 16

invalid_pilot_str: .string "Invalid\0"

pilot_id: .long 0

.section .text
.global telemetry

telemetry:


movl 4(%esp), %esi                              # punto allo spazio di memoria (32bit) subito sotto nello stack e salvo l'indirizzo del primo parametro della funzione (stringa input) in ESI
movl 8(%esp), %edi                              # stessa cosa, 2 spazi di mem sotto, 2° parametro funzione (stringa output) in EDI

pushl %eax                                      # pusho tutti i registri in sequenza sullo stack
pushl %ebx
pushl %ecx
pushl %edx


leal pilot_0_str, %edi                          # carico l'indirizzo dell'inizio della stringa piloti in EDI
check_pilot:
    xorl %ecx, %ecx                             # azzero ECX per usarlo come contatore incrementale per la stringa piloti GENERALE

    continue:
        movb (%edi, %ecx), %al                  # in AL metto la prima lettera della stringa piloti
        movb (%esi, %ecx), %bl                  # in BL metto la prima lettera della stringa del pilota in input  
        incl %ecx                               # incremento ECX e EDX per passare alla prossima lettera al ciclo successivo

        test %al, %al                           # verifico che il carattere a cui sono sia fine stringa (0)
        je end_string                           # se lo è, salto a "pilota_ok" (ho trovato l'id giusto)

        cmpb %al, %bl                           # altrimenti, confronto le lettere in AL e BL
        jne dash_string                         # se non sono uguali vado alla funzione per skippare la stringa

    jmp continue                                # altrimenti continuo con il ciclo (finisco la stringa corrente)

end_string:
    cmpb $10, %bl                               # verifico che la stringa del pilot adel file di input sia finita
    je pilot_ok                                 # se sì, salto a fine funzione per erstituire il pilot_id
    jmp invalid

dash_string:
    movb (%edi, %ecx), %al                      #
    movb (%esi, %ecx), %bl                      #
    incl %ecx                                   #

    test %al, %al                               # verifico che il carattere a cui sono sia fine stringa (0)
    je increment_pilot                          # se lo è, salto a increment_pilot
    jmp dash_string                             # altrimenti continuo a skippare



increment_pilot:
    incl %ecx
    addl %ecx, %edi                             # punto al prossimo pilota -> incremento del valore corrente di ECX il puntatore alla stringa piloti (EDI)
    
    movl pilot_id, %edx                         # incremento di 1 il valore del pilot id (uso EDX come registro temporaneo)
    incl %edx                                   #
    movl %edx, pilot_id                         #

    
    jmp check_pilot                             # continuo il check con il prossimo pilota




pilot_ok:
    
    movl 20(%esp), %esi                              # punto allo spazio di memoria (32bit) subito sotto nello stack e salvo l'indirizzo del primo parametro della funzione (stringa input) in ESI
    movl 24(%esp), %edi                              # stessa cosa, 2 spazi di mem sotto, 2° parametro funzione (stringa output) in EDI

    xorl %eax, %eax
    movl pilot_id, %eax
    addl $48, %eax
    movl %eax, (%edi)

    popl %edx                                       # poppo tutti i registri in sequenza INVERSA dallo stack
    popl %ecx
    popl %ebx
    popl %eax

    ret


invalid:
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
