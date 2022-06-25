# ------CONVERSIONE NUMERI DA STRINGA A INTERO -------
.section .data

temp_num: .long 0

.section .text
	.global str2num

.type str2num, @function

# CONVERTO STRINGA A NUMERO
str2num:

pushl %eax                                      # pusho tutti i registri in sequenza sullo stack
pushl %ebx
pushl %ecx                                      # pusho anche ecx così quando ritorno dopo il check dell'id pilota poso continuare a stampare la stringa da dove 
                                                # ero fermo prima di entrare nella str2num (=> e quidni posso stampare anche l'id pilota)
pushl %edx

# --------------------------------------------------

xorl %eax, %eax                 # resetto a zero tutti i registri primari
xorl %ebx, %ebx
# xorl %ecx, %ecx               # non resetto ecx perché mi serve per tenere conto del punto in cui sono arrivato nella stringa
xorl %edx, %edx
incl %ecx

loop1:

    movb (%esi, %ecx), %bl          # muovo ciò che sta all'indirizzo (%esi + %ecx), in %ebx 
    cmpb $44, %bl                   # verifico se il carattere "," è stato letto (ascii 44 = COMMA)

    je fine_str2num                 # se sì, salta a fine loop

    subl $48, %ebx                   # converte cifra da string a numero in ebx

    movl $10, %edx                  # mette il valore 10 in %edx
    mull %edx                        # dl è 2 byte => moltiplica ax per dx e mette il risultato in dx:ax (al primo giro sarà zero)
    addl %ebx, %eax                 # sommo ebx ad eax e lo salvo in eax, a disposizione per il prossimo giro (verrà moltipicato per 10 prima che gli venga sommato il nuovo ebx)

    inc %ecx                        # incremento di 1 ecx per passare alla cifra successiva della stringa
    jmp loop1                       # ricomincio il ciclo


fine_str2num:

leal temp_num, %edi
movl %eax, (%edi)

# --------------------------------------------------

popl %edx                                   # poppo tutti i registri in sequenza INVERSA dallo stack
popl %ecx
popl %ebx
popl %eax


ret
