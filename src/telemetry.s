.section .data

id: .long 0
current_id: .long 0
invalid_pilot_str: .ascii "Invalid\n\0"
count: .long 0

max_speed: .long 0
max_rpm: .long 0
max_temp: .long 0

current_speed: .long 0
current_rpm: .long 0
current_temp: .long 0



.section .text
.global telemetry

telemetry:

movl 4(%esp), %esi                              # punto allo spazio di memoria (32bit) subito sotto nello stack e salvo l'indirizzo del primo parametro della funzione (stringa input) in ESI
movl 8(%esp), %edi                              # punto allo spazio di memoria (32bit) ancora sotto nello stack e salvo l'indirizzo del secondo parametro della funzione (stringa output) in ESI

xorl %eax, %eax                                 # EAX contiene l'indirizzo della stringa di input, lo devo azzerare per poterlo usare in get_pilot_id
call get_pilot_id

# xorl %eax, %eax
# movl (%edi), %eax                               # salvo il pilot_id in eax
movl %eax, id                                   # lo salvo come intero nella variabile "id"

cmpl $20, id                                    # se l'id è > 20, salto alla stampa della stringa "Invalid\n\0"
jge invalid_id

movl 4(%esp), %esi                              # punto allo spazio di memoria (32bit) subito sotto nello stack e salvo l'indirizzo del primo parametro della funzione (stringa input) in ESI
movl 8(%esp), %edi                              # punto allo spazio di memoria (32bit) ancora sotto nello stack e salvo l'indirizzo del secondo parametro della funzione (stringa output) in ESI
# ESI continua a puntare alla stringa di input (0x5655a1a0)
# EDI continua a puntare alla stringa di output (0x5655a350)

# --------------------------------------------------

# salto 1a riga
xorl %eax, %eax
xorl %ebx, %ebx
xorl %ecx, %ecx
xorl %edx, %edx


skip_first_line:
    movb (%esi, %ecx), %al                              # carico il primo carattere della stringa input
    cmpb $10, %al                                       # se è linefeeed -> salto alla riga successiva - le righe di telemetria
    je telemetry_rows
    incl %ecx
    jmp skip_first_line

telemetry_rows:
    incl %ecx                                           # skippo primo carattere di linefeed \0
    
    start_parse_row:

            cmpb $0, %al
            je end                                      # se sono arrivato a fine stringa, salto alla fine

        time_field:                                     # qui EAX contiene il valore 10 -> carattere a line feed \n
            movb (%esi, %ecx), %al

            movb %al, (%edi, %edx)                      # scrivo i caratteri nella stringa di output, usando come puntatore EDX

            cmpb $44, %al
            je pilot_id_field
            incl %ecx
            incl %edx
            incl count                                  # uso count per tenere il conto dei caratteri parsati, e poter riavvolgere il puntatore in seguito
            jmp time_field

        pilot_id_field:
            call str2num

            movl %eax, current_id                         # EAX contiene il valore ritornato da str2num

            compare_ids:
                xorl %ebx, %ebx
                movb id, %al
                movb current_id, %bl
                cmp %al, %bl
                jne next_row 

                jmp row_validated

            next_row:
                movb (%esi, %ecx), %al                  # verifico di arrivare a fine riga (linefeed) e riparto senza stampare nulla
                cmpb $10, %al
                je rewind_edx
                cmpb $0, %al
                je end
                incl %ecx
                jmp next_row

            rewind_edx:
                subl count, %edx
                movl $0, count
                incl %ecx                               # incremento ecx per skippare il linefeed
                jmp start_parse_row

    row_validated:
        
        parse_validated_row:
            incl %ecx
            movb (%esi, %ecx), %al                  # verifico di arrivare a fine riga (linefeed) e riparto senza stampare nulla
            cmpb $10, %al
            je start_parse_row                      # se raggiungo il linefeed -> vai a prossima riga
            cmpb $44, %al                           
            jne parse_validated_row                 # vado avanti finché non raggiungo il campo successivo - skippando il campo ID
            
            # ALTRIMENTI: 

            # velocità
            speed:
                call str2num                                # la str2num usa EAX come input, e come output
                
                movl %eax, current_speed
                movl max_speed, %ebx
                cmpl %ebx, %eax
                jg set_new_max_speed

                increase_ecx_pointer_speed:
                    incl %ecx                               # incremento ecx per passare al campo successivo
                    movb (%esi, %ecx), %al                  # verifico di arrivare a fine campo (COMMA - 44) e continuo con rpm
                    cmpb $44, %al
                    jne increase_ecx_pointer_speed
                    jmp rpm

                set_new_max_speed:
                    movl %eax, max_speed
                    jmp increase_ecx_pointer_speed

            # giri motore
            rpm:
                call str2num

                movl %eax, current_rpm
                movl max_rpm, %ebx
                cmpl %ebx, %eax
                jg set_new_max_rpm

                increase_ecx_pointer_rpm:
                    incl %ecx
                    movb (%esi, %ecx), %al                  # verifico di arrivare a fine campo (COMMA - 44) e continuo con rpm
                    cmpb $44, %al
                    jne increase_ecx_pointer_rpm
                    jmp temp
                
                set_new_max_rpm:
                    movl %eax, max_rpm
                    jmp increase_ecx_pointer_rpm

            # temperatura
            temp:
                call str2num

                movl %eax, current_temp
                movl max_temp, %ebx
                cmpl %ebx, %eax
                jg set_new_max_temp

                increase_ecx_pointer_temp:
                    incl %ecx
                    movb (%esi, %ecx), %al                  # verifico di arrivare a fine riga (LINEFEED - 10) e continuo con rpm
                    cmpb $10, %al
                    jne increase_ecx_pointer_temp
                    jmp print_row_levels

                set_new_max_temp:
                    movl %eax, max_temp
                    jmp increase_ecx_pointer_temp


        print_row_levels:

            get_rpm_level:
                    movl current_rpm, %eax
                    cmpl $10000, %eax
                    jg high_rpm
                    cmpl $5000, %eax
                    jg medium_rpm
                    jmp low_rpm

                high_rpm:
                    incl %edx
                    movl $72, (%edi, %edx)                  # H
                    incl %edx
                    movl $73, (%edi, %edx)                  # I
                    incl %edx
                    movl $71, (%edi, %edx)                  # G
                    incl %edx
                    movl $72, (%edi, %edx)                  # H
                    incl %edx
                    movl $44, (%edi, %edx)                  # stampo virgola di fine campo

                jmp get_temp_level

                medium_rpm:
                    incl %edx
                    movl $77, (%edi, %edx)                  # M
                    incl %edx
                    movl $69, (%edi, %edx)                  # E
                    incl %edx
                    movl $68, (%edi, %edx)                  # D
                    incl %edx
                    movl $73, (%edi, %edx)                  # I
                    incl %edx
                    movl $85, (%edi, %edx)                  # U
                    incl %edx
                    movl $77, (%edi, %edx)                  # M
                    incl %edx
                    movl $44, (%edi, %edx)                  # stampo virgola di fine campo

                jmp get_temp_level

                low_rpm:
                    incl %edx
                    movl $76, (%edi, %edx)                  # L
                    incl %edx
                    movl $79, (%edi, %edx)                  # O
                    incl %edx
                    movl $87, (%edi, %edx)                  # W
                    incl %edx
                    movl $44, (%edi, %edx)                  # stampo virgola di fine campo

                jmp get_temp_level


            get_temp_level:
                    movl current_temp, %eax
                    cmpl $110, %eax
                    jg high_temp
                    cmpl $90, %eax
                    jg medium_temp
                    jmp low_temp


                high_temp:
                    incl %edx
                    movl $72, (%edi, %edx)                  # H
                    incl %edx
                    movl $73, (%edi, %edx)                  # I
                    incl %edx
                    movl $71, (%edi, %edx)                  # G
                    incl %edx
                    movl $72, (%edi, %edx)                  # H
                    incl %edx
                    movl $44, (%edi, %edx)                  # stampo virgola di fine campo

                jmp get_speed_level

                medium_temp:
                    incl %edx
                    movl $77, (%edi, %edx)                  # M
                    incl %edx
                    movl $69, (%edi, %edx)                  # E
                    incl %edx
                    movl $68, (%edi, %edx)                  # D
                    incl %edx
                    movl $73, (%edi, %edx)                  # I
                    incl %edx
                    movl $85, (%edi, %edx)                  # U
                    incl %edx
                    movl $77, (%edi, %edx)                  # M
                    incl %edx
                    movl $44, (%edi, %edx)                  # stampo virgola di fine campo

                jmp get_speed_level

                low_temp:
                    incl %edx
                    movl $76, (%edi, %edx)                  # L
                    incl %edx
                    movl $79, (%edi, %edx)                  # O
                    incl %edx
                    movl $87, (%edi, %edx)                  # W
                    incl %edx
                    movl $44, (%edi, %edx)                  # stampo virgola di fine campo

                jmp get_speed_level

            get_speed_level:
                    movl current_speed, %eax
                    cmpl $200, %eax
                    jg high_speed
                    cmpl $100, %eax
                    jg medium_speed
                    jmp low_speed


                high_speed:
                    incl %edx
                    movl $72, (%edi, %edx)                  # H
                    incl %edx
                    movl $73, (%edi, %edx)                  # I
                    incl %edx
                    movl $71, (%edi, %edx)                  # G
                    incl %edx
                    movl $72, (%edi, %edx)                  # H
                    
                jmp end_row

                medium_speed:
                    incl %edx
                    movl $77, (%edi, %edx)                  # M
                    incl %edx
                    movl $69, (%edi, %edx)                  # E
                    incl %edx
                    movl $68, (%edi, %edx)                  # D
                    incl %edx
                    movl $73, (%edi, %edx)                  # I
                    incl %edx
                    movl $85, (%edi, %edx)                  # U
                    incl %edx
                    movl $77, (%edi, %edx)                  # M
                    
                jmp end_row
                
                low_speed:
                    incl %edx
                    movl $76, (%edi, %edx)                  # L
                    incl %edx
                    movl $79, (%edi, %edx)                  # O
                    incl %edx
                    movl $87, (%edi, %edx)                  # W
                    
                jmp end_row
            


            
        end_row:
            incl %edx
            movl $10, (%edi, %edx)                  # fine riga
            # stampa a capo + vai a  riga successiva
            jmp start_parse_row

        

        # --------------------------------------------------------------------------
            movl $42, %eax # --------- CHECK
            jmp end


            movb %al, (%edi, %edx)                      # scrivo i caratteri nella stringa di output, usando come puntatore EDX
            incl %ecx
            incl %edx

            jmp parse_validated_row


# --------------------------------------------------


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
