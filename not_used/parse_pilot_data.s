.section .data

second_row_index: .long 0                       # indice che mi permette di ripartire dalla seconda riga della stringa di input
verified_id: .long 0
current_id: .long 0
output_string: .string "0000000000"

.section .text
.global parse_pilot_data 

.type parse_pilot_data @function

parse_pilot_data:

pushl %eax                                      # pusho tutti i registri in sequenza sullo stack
pushl %ebx
pushl %ecx
pushl %edx

# --------------------------------------------------

# salto 1a riga
xorl %ecx, %ecx
xorl %eax, %eax

movl (%edi), %eax                               # carico in eax l'id del pilota in input, ritornata dalla call a get_pilot_id
movl %eax, verified_id                          # verified_id contiene l'id del pilota di input (formato INT)

skip_first_line:
    movb (%esi, %ecx), %al
    cmpb $10, %al
    je telemetry_rows
    incl %ecx
    jmp skip_first_line

telemetry_rows:

    parse_row:

        time_field:                                     # qui EAX contiene il valore 10 -> carattere a line feed \n
            movb (%esi, %ecx), %al

            # TODO: stampa caratteri del tempo

            cmpb $44, %al
            je pilot_id_field
            incl %ecx
            jmp time_field

        pilot_id_field:
            call str2num                                
            movl (%edi), %eax                           # edi contiene l'indirizzo di memoria della variabile temp_num
            movl %eax, current_id

            compare_ids:
                xorl %ebx, %ebx
                movb verified_id, %al
                movb current_id, %bl
                cmp %al, %bl
                jne next_row 

                jmp row_validated

            next_row:
                movb (%esi, %ecx), %al                  # verifico di arrivare a fine riga (linefeed) e riparto senza stampare nulla
                cmpb $10, %al
                je parse_row
                incl %ecx
                jmp next_row


    row_validated:
        # TODO: parso tutti i caratteri finché non incontro COMMA, e li stampo (=> id pilota)



        movl $42, %eax # --------- CHECK

# --------------------------------------------------

popl %edx                                   # poppo tutti i registri in sequenza INVERSA dallo stack
popl %ecx
popl %ebx
popl %eax

ret

