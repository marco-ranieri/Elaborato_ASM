.section .data

id: .long 0
current_id: .long 0
invalid_pilot_str: .ascii "Invalid\n\0"
count: .long 0

max_speed: .long 0
max_rpm: .long 0
max_temp: .long 0

count_frames: .long 0
sum_speeds: .long 0

current_speed: .long 0
current_rpm: .long 0
current_temp: .long 0

edi_pointer: .long 0


.section .text
.global telemetry

telemetry:

# -------------------------- #
# ---- INIZIO PROGRAMMA ---- #
# -------------------------- #


pushl %eax                                      # salvo i valori iniziali dei registri sullo stack, per poterli recuperare a fine programma
pushl %ebx
pushl %ecx
pushl %edx

movl 20(%esp), %esi                             # punto allo spazio di memoria (32bit) subito sotto nello stack e salvo l'indirizzo del primo parametro della funzione (stringa input) in ESI
movl 24(%esp), %edi                             # punto allo spazio di memoria (32bit) ancora sotto nello stack e salvo l'indirizzo del secondo parametro della funzione (stringa output) in EDI

pushl %edi                                      # pusho EDI sullo stack per recuperarlo una volta che get_pilot_id ha finito 

xorl %eax, %eax                                 # EAX contiene l'indirizzo della stringa di input, lo devo azzerare per poterlo usare in get_pilot_id
call get_pilot_id

popl %edi                                       # recuper EDI

movl %eax, id                                   # salvo l'id pilota come integer nella variabile "id"
cmpl $20, id                                    # se l'id è > 20, salto alla stampa della stringa "Invalid\n\0"
jge invalid_id

movl 20(%esp), %esi                              # punto allo spazio di memoria (32bit) subito sotto nello stack e salvo l'indirizzo del primo parametro della funzione (stringa input) in ESI
movl 24(%esp), %edi                              # punto allo spazio di memoria (32bit) ancora sotto nello stack e salvo l'indirizzo del secondo parametro della funzione (stringa output) in ESI
# ESI continua a puntare alla stringa di input (0x5655a1a0)
# EDI continua a puntare alla stringa di output (0x5655a350)

# --------------------------------------------------

# ---- salto 1a prima riga -del file di input ---
xorl %eax, %eax
xorl %ebx, %ebx
xorl %ecx, %ecx
xorl %edx, %edx


skip_first_line:
    movb (%esi, %ecx), %al                              # carico il primo carattere della stringa input
    cmpb $10, %al                                       # se è linefeed -> salto alla riga successiva - alle righe vere e proprie di telemetria
    je telemetry_rows
    incl %ecx
    jmp skip_first_line

# --------------------------------------------------------------- #
# ---- INIZIO IL PARSING DI OGNI RIGA DELLA STRINGA DI INPUT ---- #
# --------------------------------------------------------------- #

telemetry_rows:
    incl %ecx                                           # skippo primo carattere di linefeed \0
    
    start_parse_row:

            movl $0, count                              # riazzero il contatore dei caratteri della riga

            movb (%esi, %ecx), %al
            cmpb $0, %al
            je finish_row                               # se sono arrivato a fine stringa, salto alla stampa dell'ultima riga


        dash_row_for_pilot_id:                          # skippo per arrivare al campo id pilota
            movb (%esi, %ecx), %al
            cmpb $44, %al
            je pilot_id_field
            incl %ecx
            incl %edx
            incl count                                  # uso la variabile count per tenere il conto dei caratteri parsati, e poter riavvolgere il puntatore in seguito
            jmp dash_row_for_pilot_id

        pilot_id_field:                                 # converto in numero l'id pilota
            call str2num

            movl %eax, current_id                       # EAX contiene il valore ritornato da str2num; salvo l'id pilota in current_id

            compare_ids:                                # confronto l'id con il current_id per verificare che sia il pilota che mi interessa
                xorl %ebx, %ebx
                movb id, %al
                movb current_id, %bl
                cmp %al, %bl
                jne next_row                            # se non combaciano, salto direttamente alla prossima riga

                jmp row_validated                       # se combaciano, salto al parsing completo della riga corrente

            next_row:
                movb (%esi, %ecx), %al                  # verifico di arrivare a fine riga (linefeed) e riparto senza stampare nulla
                cmpb $10, %al
                je rewind_edx                           # se sono a fine riga, vado a riavvolgere il puntatore edx
                cmpb $0, %al
                je finish_row                           # se sono a fine stringa, salto alla stampa dell'ultima riga
                incl %ecx
                jmp next_row                            # altrimenti continuo il loop

            rewind_edx:
                subl count, %edx                        # sottraggo a ecx il conteggio dei character fin qui parsati, per riportarlo al valore di inizio riga
                incl %ecx                               # incremento ecx per skippare il linefeed
                jmp start_parse_row                     # riprendo a parsare la prossima riga


# ---------------------------------------------------------------------- #
# ---- PARSING DELLA RIGA CORRISPONDENTE AL PILOTA CHE MI INTERESSA ---- #
# ---------------------------------------------------------------------- #

    row_validated:
        
        parse_validated_row:
            subl count, %ecx                            # faccio rewind di ecx ed edx, così posso scorrere tutta la riga dall'inizio
            subl count, %edx


            time_field:                                 # I° campo -> TIME
                movb (%esi, %ecx), %al
                movb %al, (%edi, %edx)                  # scrivo i caratteri nella stringa di output, usando come puntatore EDX
                cmpb $44, %al
                je skip_pilot_id
                incl %ecx
                incl %edx
                jmp time_field
            
            skip_pilot_id:                              # skippo il II° campo -> id pilota
                incl %ecx
                movb (%esi, %ecx), %al                      
                cmpb $44, %al
                jne skip_pilot_id


            # III° campo -> velocità
            speed:
                call str2num                            # la str2num usa EAX come input, e come output
                
                addl %eax, sum_speeds                   # aggiungo la velocità alla sommatoria delle velocità
                incl count_frames                       # incremento il numero di frames da conteggiare

                movl %eax, current_speed                # confronto la velocità corrente con la max_speed memorizzata, e se maggiore la aggiorno
                movl max_speed, %ebx
                cmpl %ebx, %eax
                jg set_new_max_speed

                increase_ecx_pointer_speed:
                    incl %ecx                               # incremento ecx per passare al campo successivo
                    movb (%esi, %ecx), %al                  # verifico di arrivare a fine campo (COMMA - 44) e continuo con rpm
                    cmpb $44, %al
                    jne increase_ecx_pointer_speed
                    jmp rpm

                set_new_max_speed:                      # aggiorno la velocità massima
                    movl %eax, max_speed
                    jmp increase_ecx_pointer_speed

            # IV° campo -> giri motore
            rpm:
                call str2num

                movl %eax, current_rpm                  # confronto i giri motore correnti con i max_rpm memorizzati, e se maggiori li aggiorno
                movl max_rpm, %ebx
                cmpl %ebx, %eax
                jg set_new_max_rpm

                increase_ecx_pointer_rpm:
                    incl %ecx                               # incremento ecx per passare al campo successivo
                    movb (%esi, %ecx), %al                  # verifico di arrivare a fine campo (COMMA - 44) e continuo con rpm
                    cmpb $44, %al
                    jne increase_ecx_pointer_rpm
                    jmp temp
                
                set_new_max_rpm:                        # aggiorno gli rpm massimi
                    movl %eax, max_rpm
                    jmp increase_ecx_pointer_rpm

            # V° campo -> temperatura
            temp:
                call str2num

                movl %eax, current_temp                 # confronto la temperatura corrente con la max_temp memorizzata, e se maggiore la aggiorno
                movl max_temp, %ebx
                cmpl %ebx, %eax
                jg set_new_max_temp

                increase_ecx_pointer_temp:
                    incl %ecx                               # incremento ecx per passare al campo successivo
                    movb (%esi, %ecx), %al                  # verifico di arrivare a fine riga (LINEFEED - 10) e continuo con rpm
                    cmpb $10, %al
                    jne increase_ecx_pointer_temp
                    jmp print_row_levels

                set_new_max_temp:                       # aggiorno la temperatura massima
                    movl %eax, max_temp
                    jmp increase_ecx_pointer_temp


# ----------------------------------------------------------------------------------- #
# ---- STAMPA DEI LIVELLI ASSOCIATI A RPM, TEMP E SPEED, NELLA STRINGA DI OUTPUT ---- #
# ----------------------------------------------------------------------------------- #

        print_row_levels:

            get_rpm_level:                                  # confronto gli rpm della riga corrente con le soglie definite
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


            get_temp_level:                                 # confronto la temperatura della riga corrente con le soglie definite
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

            get_speed_level:                                # confronto la velocità della riga corrente con le soglie definite
                    movl current_speed, %eax
                    cmpl $250, %eax
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
            

        # ---- AGGIUNGO FINE RIGA (A CAPO, E INCREMENTO PUNTATORI)     
        end_row:
            incl %edx
            movl $10, (%edi, %edx)                      # aggiungo fine riga
            incl %ecx
            incl %edx                                   # incremento edx per spostarmi al prossimo character e iniziare una nuova riga dell'output
            jmp start_parse_row



# ---- RIGA PILOTA NON VALIDO ----------------------------------------------

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


# ---------------------------------------------------------------------- #
# ---- ULTIMA RIGA (MAX_RPM, MAX_TEMP, MAX_SPEED, AVERAGE_SPEED) ------- # 
# ---------------------------------------------------------------------- #


finish_row:                                         # stampo l'ultima riga

    subl count, %edx
    movl %edx, edi_pointer                          # salvo il puntatore per la stringa di output 

    
# RPM----------------------------------------

    finish_row_rpm:
        movl max_rpm, %eax

        # ---- num2str:   
        movl $10, %ebx                              # carica 10 in EBX (usato per le divisioni)
        movl $0, %ecx                               # azzera il contatore ECX

        keep_dividing_rpm:
            xorl %edx, %edx                         # azzera il contenuto di DL
            divl %ebx                               # divide per 10 il numero ottenuto
            addb $48, %dl                           # aggiunge 48 al resto della divisione

            pushl %edx                              # salvo il resto della divisione nello stack
            
            inc %ecx                                # incrementa il contatore ECX
            cmp $0, %eax                            # controlla se il contenuto di EAX è 0
            jne keep_dividing_rpm

            movl $0, %ebx                           # azzera un secondo contatore in EBX
            movl edi_pointer, %edx                  # recupera il puntatore a EDI

        mirror_and_print_rpm:

            popl %eax                               # recupero dallo stack il carattere e lo aggiungo alla stringa di output
            movb %al, (%edi, %edx)
            incl %edx

            loop mirror_and_print_rpm


    movl $44, (%edi, %edx)                          # aggiungo una virgola e incremento e salvo il puntatore
    incl %edx
    movl %edx, edi_pointer          


# TEMP --------------------------------------

    finish_row_temp:
        movl max_temp, %eax

        # ---- num2str:   
        movl $10, %ebx                              
        movl $0, %ecx                               

        keep_dividing_temp:
            xorl %edx, %edx                         
            divl %ebx                               
            addb $48, %dl                           

            pushl %edx
            
            inc %ecx                               
            cmp $0, %eax                            
            jne keep_dividing_temp

            movl $0, %ebx                           
            movl edi_pointer, %edx                  

        mirror_and_print_temp:

            popl %eax
            movb %al, (%edi, %edx)
            incl %edx

            loop mirror_and_print_temp


    movl $44, (%edi, %edx)
    incl %edx        
    movl %edx, edi_pointer                 


# MAX_SPEED ---------------------------------

    finish_row_max_speed:
        movl max_speed, %eax

        # ---- num2str:   
        movl $10, %ebx                              
        movl $0, %ecx                               

        keep_dividing_max_speed:
            xorl %edx, %edx                         
            divl %ebx                               
            addb $48, %dl                           

            pushl %edx
            
            inc %ecx                               
            cmp $0, %eax                            
            jne keep_dividing_max_speed

            movl $0, %ebx                           
            movl edi_pointer, %edx                  

        mirror_and_print_max_speed:

            popl %eax
            movb %al, (%edi, %edx)
            incl %edx

            loop mirror_and_print_max_speed

    
    movl $44, (%edi, %edx)
    incl %edx
    movl %edx, edi_pointer     


# AVERAGE_SPEED -----------------------------

    finish_row_average_speed:

        movl %edx, edi_pointer                           

        xorl %edx, %edx
        movl sum_speeds, %eax                       # recupero la somma delle velocità e la salvo in EAX
        movl count_frames, %ebx                     # recupero il numero di frames e lo salvo in EBX

        divl %ebx                                   # divido la somma delle velocità per i frames -> il quoziente sarà in EAX

        # ---- num2str:   
        movl $10, %ebx                              
        movl $0, %ecx                               

        keep_dividing_average_speed:
            xorl %edx, %edx                         
            divl %ebx                               
            addb $48, %dl                           

            pushl %edx
            
            inc %ecx                                
            cmp $0, %eax                            
            jne keep_dividing_average_speed

            movl $0, %ebx                           
            movl edi_pointer, %edx                  

        mirror_and_print_average_speed:

            popl %eax
            movb %al, (%edi, %edx)
            incl %edx

            loop mirror_and_print_average_speed

    movl $10, (%edi, %edx)                          # aggiungo alla stringa di output il linefeed \n
    incl %edx
    movl $0, (%edi, %edx)                           # aggiungo alla stringa di output il fine stringa \0


# ------------------------ #
# ---- FINE PROGRAMMA ---- #
# ------------------------ #

end:

popl %edx                                           # recupero i valori iniziali dei registri prima di ritornare al main.c
popl %ecx
popl %ebx
popl %eax

ret
