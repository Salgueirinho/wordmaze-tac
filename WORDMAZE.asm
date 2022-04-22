.8086
.model small
.stack 2048

dseg segment para public 'data'

		Tempo_init			dw		99				; Guarda O Tempo de inicio do jogo
		Tempo_j				dw		99				; Guarda O Tempo que decorre o  jogo
		Tempo_limite		dw		0				; tempo de fim do jogo
		Segundos_ant		dw		?				;segundo anterior para ajudar na contagem do tempo
		Segundos_reais  	dw		?				;segundo real
		Str_Segundos    	db      "    "			; string para guardar os segundos do jogo
		NomeJogador			db		"                $"	;nome a preencher pelo jogador
		randomx				db      3,24,47,47,5,27
		randomy				db  	4,10,18,2,18,2
		;buffers para tratar do top 10 quando o jogador conclui o jogo
		; guardam em memoria o conteudo do ficheiro top10.txt 
		Top10_buffer		db		'                     ',13,10
							db		'                     ',13,10
							db		'                     ',13,10
							db		'                     ',13,10
							db		'                     ',13,10
							db		'                     ',13,10
							db		'                     ',13,10
							db		'                     ',13,10
							db		'                     ',13,10
							db		'                     '
							
		Top10_buffer_Apoio	db		'                     ',13,10
							db		'                     ',13,10
							db		'                     ',13,10
							db		'                     ',13,10
							db		'                     ',13,10
							db		'                     ',13,10
							db		'                     ',13,10
							db		'                     ',13,10
							db		'                     ',13,10
							db		'                     '
		

		posicao_top10		db		0				;apoio para tratar o top10
		Pontuacao			dw		0				;pontução do jogador atual
		Str_Pontucao		db      "0000$"			;string para ajudar a mostrar ao utilizador
        
		; nivel e palavras de cada nivel
		nivel				db		1
		palavra1	  		db	    "AGUA          $"
		palavra2	  		db	    "ISEC          $"
		palavra3	  		db	    "GARRAFAO      $"
		palavra4	  		db	    "BENFICA       $"
		palavra5	  		db	    "LINGUARUDO    $"		
		palavra_atual		db		"AGUA          $"
		Construir_palavra	db		"              $" ;palavra que o jogador está a contruir	
		
		Dim_nome			db		14		; Comprimento do Nome
		concluido 			db		0		;palavra igual: valor 1. Palavra diferente: valor 0
		JogoaDecorrer 		db		0		; igual a 0 enquanto o jogo não decorre. igual a 1  quando o jogo decorre
		
		; algumas strings para mostrar ao utilizador
		Fim_Ganhou			db	    " Ganhou $"	
		Fim_Perdeu			db	    " Perdeu $"	
		InsiraNome			db      "INSIRA SEU NOME (MAX: 14) $"
		Pontucao_texto		db      "Pontuacao:  $"
		top10_texto			db      "TOP 10  $"
		TextoParaSair 		db		"ESC para voltar $"
		SemPontucao			db		"Tenta outra vez $"
        Erro_Open       	db      'Erro ao tentar abrir o ficheiro$'
        Erro_Ler_Msg    	db      'Erro ao tentar ler do ficheiro$'
		erro_escrever    	db      'Erro ao tentar ler do ficheiro$'
        Erro_Close      	db      'Erro ao tentar fechar o ficheiro$'
		
		;ficheiros 
        labiFich         	db      'fich\labi.TXT',0
		menuFich        	db      'fich\menu.TXT',0
		ajudaFich			db		'fich\ajuda.TXT',0
		top10Fich			db		'fich\top10.TXT',0
        HandleFich      	dw      0
        car_fich        	db      ?

		Car					db	32	; Guarda um caracter do Ecran 
		Cor					db	7	; Guarda os atributos de cor do caracter
		POSy				db	4	; a linha pode ir de [1 .. 25]
		POSx				db	3	; POSx pode ir [1..80]	
		POSya				db	3	; Posição anterior de y
		POSxa				db	3	; Posição anterior de x
	
dseg ends

cseg segment para public 'code'
	assume cs:cseg, ds:dseg
	
;########################################################################
goto_xy	macro		POSx,POSy
		mov		ah,02h
		mov		bh,0		; numero da página
		mov		dl,POSx
		mov		dh,POSy
		int		10h
endm

;########################################################################
; MOSTRA - Faz o display de uma string terminada em $

MOSTRA MACRO STR 
MOV AH,09H
LEA DX,STR 
INT 21H
ENDM

; FIM DAS MACROS
	
	
;########################################################################
; LE UMA TECLA	

LE_TECLA	PROC
sem_tecla:
		mov bl,JogoaDecorrer
		cmp bl,1
		jne	jogo_nao_decorre			; Temporizador sempre a contar quando
		call TEMPORIZADOR				; o jogo é iniciado e quando nenhum tecla é premida
		

jogo_nao_decorre:		
		MOV	AH,0BH
		INT 21h
		cmp AL,0
		je	sem_tecla
		
		MOV	AH,08H
		INT	21H
		MOV	AH,0
		CMP	AL,0
		JNE	SAI_TECLA
		MOV	AH, 08H
		INT	21H
		MOV	AH,1

SAI_TECLA:	RET
LE_TECLA	endp


;ROTINA PARA APAGAR ECRAN

apaga_ecran	proc
			mov		ax,0B800h
			mov		es,ax
			xor		bx,bx
			mov		cx,25*80
		
apaga:		mov		byte ptr es:[bx],' '
			mov		byte ptr es:[bx+1],7
			inc		bx
			inc 	bx
			loop	apaga
			
			goto_xy 0,0			;coloca o cursor no inicio do ecra
			ret
apaga_ecran	endp

;Função de apoio a trata 10 copia os valores de  um buffer para o outro
COPIA_BUFFER proc	
			pushf
			push ax
			push bx
			push cx
			push dx
			xor si,si
			mov cx,228						;228 bytes (tamanho do buffer) 
ciclo_copia:
			mov al,Top10_buffer[si]				
			mov Top10_buffer_Apoio[si],al		;coloca todos os caracteres do top10_buffer no de apoio
			inc si
loop ciclo_copia			
			
			pop dx
			pop cx
			pop bx
			pop ax
			popf	
			
	ret
COPIA_BUFFER endp


;############################################
;Trata do top 10
TRATA_TOP10 proc
			pushf
			push ax
			push bx
			push cx
			push dx

			xor si,si
abrir_ficheiro_leitura:
			
			lea dx,	top10Fich			
			mov ah, 3dh
			mov al, 00h				;Abre ficheiro para leitura
			int 21h
			jc      erro_abrir1		; se der erro é porque ainda não existe por isso é preciso criar o ficheiro
			mov     HandleFich,ax	
			jmp     ler_ciclo

erro_abrir1:
			lea dx,	top10Fich			;cria um ficheiro novo
			mov cx,	00h				
			mov ah, 3ch		
			mov al, 00h					;cria ficheiro se der erro a abrir
			int 21h						; dá erro porque o ficheiro não existe antes para leitura
			jc      erro_abrir2
			mov     HandleFich,ax
			jmp     ler_ciclo

erro_abrir2:			
			mov     ah,09h				;erro a criar ficheiro
			lea     dx,Erro_Open
			int     21h
			jmp     sai_fim


ler_ciclo:
			mov     ah,3fh
			mov     bx,HandleFich			
			mov     cx,1					;lê caracter a caracter para um buffer
			lea     dx,Top10_buffer[si]		; até chegar ao final do ficheiro
			int     21h
			jc		erro_ler				
			cmp		ax,0					;EOF?  retorna o numero de bytes lidos. 0 quando chega ao fim do ficheiro
			je		fecha_ficheiro
			inc 	si
			jmp		ler_ciclo


erro_ler:
        mov     ah,09h
        lea     dx,Erro_Ler_Msg			; mensagem de erro a ler
        int     21h
		
fecha_ficheiro:
        mov     ah,3eh
        mov     bx,HandleFich			;fecha ficheiro
        int     21h
        jnc     sai_f1

        mov     ah,09h
        lea     dx,Erro_Close			; mensagem de erro a fechar
        Int     21h
sai_f1:

		call COPIA_BUFFER				;copia o buffer com memoria do ficheiro para outro

comparar_pontucao:
		xor dx,dx 
		mov si,17
		xor di,di
		mov cx, 10
		mov bl,0
		
		mov posicao_top10,0
		mov ah,nivel
		cmp ah,1
		jne loop_jogador
		goto_xy 35,6
		MOSTRA  SemPontucao
		Call LE_TECLA
		xor ax,ax
		jmp sai_fim
		xor ah,ah
		
loop_jogador:

	loop_pontuacao:					; comparação de cada caracter da str_pontuacao com a pontuação dos top 10
		mov al,Top10_buffer[si]		
		cmp al,Str_Pontucao[di]
		ja  prox					;se o caracter do jogador do buffer for maior avança para o proximo jogador
		jb	coloca_no_top_10					;Se a str_pontuacao for maior (jogador atual)
		inc	di
		inc si
		inc dx						;contador para este loop, para voltar o si ao inicio da pontuação no buffer
		cmp di, 4
		je	prox
	jmp	loop_pontuacao
	prox:
		inc bl						; incrementa a posicao
		sub si, dx					;voltar para o primeiro caracter da pontucao
		add si,23					; avança para o proximo jogador no array
		xor di,di
loop loop_jogador					;loop entre as varias posições do top10
		jmp sai_fim					; se sair do loop é porque não entra no top 10


coloca_no_top_10:
		mov posicao_top10,bl	
		xor si,si
									; Bl tem a posição do jogador atual no top 10 		
		xor ax,ax
		mov al,bl					; passa o posição para al
		xor bx,bx
		mov	bl,23
		xor dx,dx
		xor di,di
		
		
		call PREENCHE_NOME				;o utilizador escolhe o seu nome

										;ciclo para colocar o jogador atual na posição certa do top10
		mul bl							;ax tem a posição para o array do top10 
		
		mov si, ax						;indice para o array do top10
		ciclo_nome:		
			mov dl, NomeJogador[di]			;coloca o nome do jogador atual no buffer final
			mov Top10_buffer_Apoio[si],dl	;na posição correta
			inc di
			inc si
			cmp di, 14					;fim do nome do jogador (max de 14 caracteres)
			je sai_ciclo_nome
			jmp ciclo_nome
sai_ciclo_nome:
			add si,3
			xor di,di					
			ciclo_pontucao:			
			mov	dl, Str_Pontucao[di]
			mov Top10_buffer_Apoio[si],dl	;copia a pontuação do jogador atual
			inc di							; para a posição a seguir ao nome no buffer final
			inc si
			cmp di, 4
			je sai_ciclo_pontuacao
			jmp ciclo_pontucao
sai_ciclo_pontuacao:

mover_jogadores_para_baixo:				;mover uma posição aos jogadores a seguir ao jogador atual
			xor ax,ax
			xor bx,bx
			xor dx,dx
			xor si,si
			xor di,di
			mov bl,23
			
			mov al,posicao_top10		;posição do jogador atual no top10
			mul bl				
			xor ah,ah
			mov si,ax					;index para o top10_buffer
			add al,23					;posicao do proximo jogador 
			xor ah,ah
			mov di,ax					;index para o top10_buffer_apoio
	ciclo_jogadores:
			mov dl,top10_buffer[si]
			mov Top10_buffer_Apoio[di],dl
			inc si
			inc di
			cmp di,228					; ultimo caracter do array
			je escrever_ficheiro_top10
			jmp ciclo_jogadores
			
										;aqui o buffer de apoio tem o top 10 reorganizado
										; portanto é só voltar a escrever no ficheiro
	
escrever_ficheiro_top10:
		mov		ah, 3ch					; Abrir o ficheiro para escrita
		mov		cx, 00H					; Define o tipo de ficheiro ??
		lea		dx, top10Fich			; DX aponta para o nome do ficheiro 
		int		21h						; Abre efectivamente o ficheiro (AX fica com o Handle do ficheiro)
		jnc		escrevef				; Se não existir erro escreve no ficheiro
	
		mov		ah, 09h
		lea		dx, Erro_Open			;erro a abrir
		int		21h						
	
		jmp		sai_fim

escrevef:
		mov		bx, ax					; Coloca em BX o Handle
    	mov		ah, 40h					; indica que é para escrever
    	
		lea		dx, Top10_buffer_Apoio			; DX aponta para a infromação a escrever
    	mov		cx, 228					; CX fica com o numero de bytes a escrever
		int		21h						; Chama a rotina de escrita
		jnc		fechar1					; Se não existir erro na escrita fecha o ficheiro
	
		mov		ah, 09h
		lea		dx, erro_escrever
		int		21h
fechar1:
        mov     ah,3eh					;fechar o ficheiro
        mov     bx,HandleFich
        int     21h
        jnc     sai_fim					

        mov     ah,09h
        lea     dx,Erro_Close			;erro a fechar
        Int     21h

sai_fim:			
			call apaga_ecran
			pop dx
			pop cx
			pop bx
			pop ax
			popf
			
			ret 
TRATA_TOP10 endp

;########################################################################
; IMP_FICH
IMP_FICH	PROC

		;abre ficheiro
        mov     ah,3dh
        mov     al,0
        ;lea     dx,Fich			;Para usar em ficheiros à escolha mais tarde
        int     21h
        jc      erro_abrir
        mov     HandleFich,ax
        jmp     ler_ciclo

erro_abrir:
        mov     ah,09h
        lea     dx,Erro_Open
        int     21h
        jmp     sai_f

ler_ciclo:
        mov     ah,3fh
        mov     bx,HandleFich
        mov     cx,1
        lea     dx,car_fich
        int     21h
		jc		erro_ler
		cmp		ax,0				;EOF?
		je		fecha_ficheiro
        mov     ah,02h
		mov		dl,car_fich			;imprime caracter a caracter no ecrã
		int		21h
		jmp		ler_ciclo

erro_ler:
        mov     ah,09h
        lea     dx,Erro_Ler_Msg
        int     21h

fecha_ficheiro:
        mov     ah,3eh
        mov     bx,HandleFich
        int     21h
        jnc     sai_f

        mov     ah,09h
        lea     dx,Erro_Close
        Int     21h
sai_f:	
		RET
		
IMP_FICH	endp		

;#####################################################3
;Verificar se carater pertence à palavra

VERIFICA_CARACTERE proc
		PUSHF
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX	

		xor si,si
		mov ah,Car				;move carater do cursor 
		mov cl, Dim_nome		;tamanho das palavras

loop_verifica_car:
		mov bl, palavra_atual[si]		
		cmp bl,ah					; se for igual preenche na mesma posição
		jne caracter_diferente
		mov Construir_palavra[si],ah	
		
caracter_diferente:		
		inc si						; passa à proxima posição
		loop loop_verifica_car		;repete 14 vezes (Dim_nome)

		goto_xy 10,21
		MOSTRA Construir_palavra	;imprime no ecra a palavra que está a ser construída
	
		POP DX		
		POP CX
		POP BX
		POP AX
		POPF
		ret
VERIFICA_CARACTERE endp	
	
	
;##############################
;Aumenta a pontuação segundo o tempo que falta para cada nivel

AUMENTA_PONTUACAO proc
	pushf
	push ax

	xor ax,ax
	;Aumenta a pontuação
	mov ax, Tempo_j
	add ax, Pontuacao
	mov Pontuacao,ax
		
	pop ax
	popf
	ret
AUMENTA_PONTUACAO endp
;##########################################
;Função que imprime a pontuação
IMPRIME_PONTUACAO proc
		PUSHF
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX	
		
		xor ax,ax
		xor bx,bx
		mov 	ax, Pontuacao		
		MOV 	bl, 10     		
		div 	bl							
		add		ah,	30h						; Caracter Correspondente às unidades			 
		MOV 	Str_Pontucao[3],ah	
		mov 	ah,0
		div 	bl	
		add 	al, 30h						;centenas
		add 	ah, 30h						;dezenas
		MOV 	Str_Pontucao[2],ah
		mov     Str_Pontucao[1],al

		goto_xy 51,20
		MOSTRA Str_Pontucao				; mostra a string da pontuação no ecrã
		
		POP DX		
		POP CX
		POP BX
		POP AX
		POPF
		ret
IMPRIME_PONTUACAO endp

;############################
;Repõe o tempo de jogo
RESET_TEMPO_JOGO proc
	pushf
	push ax

	;Reset ao tempo de jogo
	mov ax,Tempo_init
	mov Tempo_j,ax
	
	pop ax
	popf

	ret
RESET_TEMPO_JOGO endp
;#################################
;Coloca a palavra a construir vazia (com espaços)
LIMPA_PALAVRA_CONSTRUIR proc
	pushf
	push ax
	push bx
	push cx
	push dx		
	
	;limpar a palavra a construir
	mov ah, 32				;espaço
	mov cl,Dim_nome			;tamanho da palavra
	xor si,si
loop_reset_pal:
	mov Construir_palavra[si],ah	;coloca espaços em todas as posições da string
	inc si
loop loop_reset_pal
	goto_xy 10,21
	MOSTRA 	Construir_palavra			; imprime a palavra do nivel atual vazia

	pop dx
	pop cx
	pop bx
	pop ax
	popf

	ret
LIMPA_PALAVRA_CONSTRUIR endp

;############################
;Avança um nivel e passa a palavra do proximo nivel para a palavra atual
ProximoNivel proc
	pushf
	push ax
	push bx
	push cx
	push dx
				
	call RESET_TEMPO_JOGO					;coloca o tempo a 99 
	call LIMPA_PALAVRA_CONSTRUIR			;limpa a palavra a construir
				
	xor ax,ax
	mov ah,nivel
	inc ah					;passa ao proximo nivel
	cmp ah,6	
	je fim_copiar_palavra
	mov nivel,ah			; guarda o nivel na variavel
	
	call   	RANDOM_POS				;posição aleatoria
	
	cmp ah,2
	jne	copiarpal3		
	
copiarpal2:						
	xor si,si
	mov cl, Dim_nome
loopcopiar2:
	mov bl,palavra2[si]			;copia a palavra2 
	mov palavra_atual[si],bl	
	inc si
	loop loopcopiar2
	jmp fim_copiar_palavra	
	
copiarpal3:		
	cmp ah,3
	jne	copiarpal4		
			
	xor si,si
	mov cl, Dim_nome
loopcopiar3:
	mov bl,palavra3[si]
	mov palavra_atual[si],bl	
	inc si						;copia a palavra3
	loop loopcopiar3
	jmp fim_copiar_palavra	
	
copiarpal4:		

	cmp ah,4
	jne	copiarpal5
	
	xor si,si
	mov cl, Dim_nome
loopcopiar4:
	mov bl,palavra4[si]
	mov palavra_atual[si],bl	;copia a palavra4
	inc si
	loop loopcopiar4
	jmp fim_copiar_palavra
	
copiarpal5:		
	cmp ah,5
	jne fim_copiar_palavra
	xor si,si
	mov cl, Dim_nome
loopcopiar5:
	mov bl,palavra5[si]
	mov palavra_atual[si],bl	;copia a palavra5
	inc si		
	loop loopcopiar5

fim_copiar_palavra:

	pop dx
	pop cx
	pop bx
	pop ax
	popf

	ret
ProximoNivel endp

;#########################################3
;Função auxiliar para o temporizador
;Lê os segundos reais e guarda-os

Ler_SEGUNDOS proc	 
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
		PUSHF
		
		MOV AH, 2CH             	; Buscar a tempo atual real
		INT 21H                 
		
		XOR AX,AX
		MOV AL, DH              	; segundos para al
		mov Segundos_reais, AX		; guarda segundos na variavel correspondente
	
		POPF
		POP DX
		POP CX
		POP BX
		POP AX
 		RET 
Ler_SEGUNDOS   endp
;#####################################################
;Função que verifica sempre que passa um segundo e decrementa o tempo de jogo
TEMPORIZADOR proc
		PUSHF
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX	
		
		mov ax, Tempo_j
		cmp ax,	0
		je fim_temporizador
		
		CALL 	Ler_SEGUNDOS				; Lê segundos do sistema
		
		MOV		AX, Segundos_reais
		cmp		AX, Segundos_ant			; VErifica se os segundos mudaram desde a ultima leitura
		je		fim_temporizador			; Se a hora não mudou desde a última leitura sai.
		mov		Segundos_ant, AX			; Se segundos são diferentes actualiza informação do tempo 
		mov 	ax, Tempo_j
		dec 	ax								;Diminui o tempo de jogo 1 segundo
		mov 	Tempo_j, ax						;guarda denovo o tempo decrementado
		
		;Cópia do valor decimal para string
		MOV 	bl, 10     
		div 	bl
		add 	al, 30h						; Caracter Correspondente às dezenas
		add		ah,	30h						; Caracter Correspondente às unidades
		MOV 	Str_Segundos[0],al			
		MOV 	Str_Segundos[1],ah
		MOV 	Str_Segundos[2],'$'

fim_temporizador:
		goto_xy 55,0
		MOSTRA Str_Segundos
		
		POP DX		
		POP CX
		POP BX
		POP AX
		POPF
		ret
TEMPORIZADOR endp

;######################################
;Verificar palavra completa
VERIFICA_PALAVRA proc
		PUSHF
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX	
		
		xor si,si
		mov cl,Dim_nome					;tamanho das palavras
loop_palavra:
		mov al,palavra_atual[si]	
		mov ah,Construir_palavra[si]	;compara todos os caracteres
		cmp al,ah
		jne fim_verifica_palavras		;se algum caracter for diferente sai  fora do ciclo pois a palavra ainda não é igual
		inc si
		loop loop_palavra				; loop tamanho das palavras
		; se a palavra estiver completa...
		call 	AUMENTA_PONTUACAO		; aumenta a pontuação quando palavra completa
		mov 	al,nivel				
		cmp	 	al,5
		je 		jogo_concluido			;palavra completa e ultimo nivel
		call 	ProximoNivel			; avança o nivel se a palavra for completa e não estiver no ultimo nivel
		jmp 	fim_verifica_palavras
jogo_concluido:
		mov concluido,1
		
fim_verifica_palavras:
		
		POP DX		
		POP CX
		POP BX
		POP AX
		POPF
		ret
VERIFICA_PALAVRA endp

;##################################
;Imprime o nivel do jogo no ecrã

IMPRIME_NIVEL proc
	goto_xy 8,0
	
	mov     dl,nivel
	add 	dl,48
	mov     ah,02h
	int     21h

	ret
IMPRIME_NIVEL endp

;##############3
;Posição randomx

RANDOM_POS proc
			PUSHF
			PUSH AX
			PUSH BX
			PUSH CX
			PUSH DX	
salto:			
			mov ah,2ch		
			int 21h			;dl tem os milesimos de segundo
			
			xor ax,ax
			mov al, dl
			mov cl,10
			div cl			;al contem o digito das dezenas (entre 0 e 9)
			xor ah,ah
			cmp al,5
			ja salto
			mov si,ax

			mov al,randomx[si]
			mov POSx,al
			mov al,randomy[si]	;atribuir os valores random à posição
			mov	POSy,al
			
			mov Car,32
			
			POP DX		
			POP CX
			POP BX
			POP AX
			POPF
			ret
RANDOM_POS endp

;############################3
;Função que dá reset às variaveis para iniciar o jogo de novo

NOVO_JOGO proc
			PUSHF
			PUSH AX
			PUSH BX
			PUSH CX
			PUSH DX	
			call LIMPA_PALAVRA_CONSTRUIR
			mov nivel,1					;Recolocar nivel a 1 e a palavra 1 			
			xor si,si
			mov cl, Dim_nome			;tamanho da palavra
loopcopiar1:	
			mov bl,palavra1[si]				
			mov palavra_atual[si],bl		;coloca a palavra1 na palavra_atual / caracter a caracter
			inc si
		loop loopcopiar1				;loop tamanho da palavra
			
			mov Pontuacao,0				;reset à pontuação
				
			POP DX		
			POP CX
			POP BX
			POP AX
			POPF
		ret
NOVO_JOGO endp
;#########################
;Limpa o nome do jogador
LIMPAR_JOGADOR proc
			pushf
			push ax
			push bx
			push cx
			push dx
			xor si,si		;coloca si a 0
ciclo_nome:	
			mov NomeJogador[si],32
			inc si
			cmp NomeJogador[si],'$'
			je sai_fora
			jmp ciclo_nome

sai_fora:

			pop dx
			pop cx
			pop bx
			pop	ax
			popf
			
			ret
LIMPAR_JOGADOR endp

;#########################
;função que preenche o nome do utilizador
PREENCHE_NOME proc
			pushf
			push ax
			push bx
			push cx
			push dx
	
								; Pede nome ao Jogador	
								; e prenche caracter a caracter
nome_jogador:
		goto_xy 30,7
		MOSTRA InsiraNome		; "Insira o nome: "
		xor si,si	
	
ciclo_nome_preen:
		xor ax, ax
		goto_xy 30,9
		MOSTRA NomeJogador		; mostra o nome enquanto é prenchido
		
		call LE_TECLA
		cmp al,13				; sai do nome se for ENTER
		je sai_do_nome
		cmp	al,8				;Backspace para apagar caracter
		jne adiciona_caracter	
		cmp si,0
		je	salto
		dec si
		mov NomeJogador[si],32	; coloca um espaço
		jmp salto
adiciona_caracter:
		mov NomeJogador[si],al	;coloca caracter no nome
		inc si					; avança caracter
salto:
		cmp si,14				;tamanho maximo do nome
		je sai_do_nome				;sai do preenchimento
		jmp ciclo_nome_preen
		
sai_do_nome:	

			pop dx
			pop cx
			pop bx
			pop	ax
			popf
		ret
PREENCHE_NOME endp
;############################3
;função chamada quando o jogador conclui o jogo e  ajuda a tratar o top10 ,etc
FIM_JOGO proc
		pushf
		push ax
		push bx
		push cx
		push dx
			call apaga_ecran
			goto_xy 10,0
			MOSTRA top10_texto			;mostra "TOP 10"
			mov bl,concluido
			cmp bl,1
			jne perdeu			
			goto_xy 34,3
			MOSTRA Fim_Ganhou			; mostra "Ganhou"
			
			jmp sai_fora
perdeu:
			goto_xy 34,3			; mostra "Perdeu"
			MOSTRA Fim_Perdeu

sai_fora:
			goto_xy 34,5
			MOSTRA Pontucao_texto		;mostra "Sua pontucao: "
			goto_xy 46,5
			MOSTRA Str_Pontucao			; mostra pontuação do jogador atual
			goto_xy 0,2
			
			lea		dx,top10Fich
			call	IMP_FICH			; mostra no ecra o top 10
			
			call	TRATA_TOP10			; verifica se o jogador pertence ao top 10
			
		pop dx
		pop cx
		pop bx
		pop ax
		popf
		
		ret
FIM_JOGO endp
;########################################################################
; Avatar
AVATAR	PROC
			mov		ax,0B800h
			mov		es,ax
			
			
			mov 	Car,32
			mov 	JogoaDecorrer, 1
			call 	LIMPAR_JOGADOR		;limpa o nome do jogador (quando o jogo é iniciado mais vezes sem fechar)
			call	NOVO_JOGO		;chama função que coloca o nivel a 1 e a palavra1 na palavra_atual 
			call 	RESET_TEMPO_JOGO					;coloca o tempo a 99 
			call   	RANDOM_POS							;posição aleatoria
			
			goto_xy	POSx,POSy		; Vai para nova possição
			mov 	ah, 08h			; Guarda o Caracter que está na posição do Cursor
			mov		bh,0			; numero da página
			int		10h			
			mov		Car, al			; Guarda o Caracter que está na posição do Cursor
			mov		Cor, ah			; Guarda a cor que está na posição do Cursor	
			
CICLO:		goto_xy	POSxa,POSya		; Vai para a posição anterior do cursor
			mov		ah, 02h
			mov		dl, Car			; Repoe Caracter guardado 
			int		21H		
		
			goto_xy	POSx,POSy		; Vai para nova possição
			mov 	ah, 08h
			mov		bh,0			; numero da página
			int		10h		
			
			cmp 	al,177			; Al tem o ultimo caracter onde o cursor está
			je		igual_parede	; Se o caracter for igual à parede o cursor volta para a posição anterior
			mov		Car, al			; Guarda o Caracter que está na posição do Cursor
			mov		Cor, ah			; Guarda a cor que está na posição do Cursor
			jmp 	fim_volta_pos_anterior

igual_parede:
			mov bl,POSxa					;volta para a posição anterior
			mov POSx,bl
			mov bl,POSya
			mov POSy,bl
fim_volta_pos_anterior:	
			
			call 	VERIFICA_CARACTERE		; verifica se Car pertence à palavra e mostra a construção no ecra
			call    VERIFICA_PALAVRA		; verifica se a palavra está completa e avança o nivel se estiver
			call 	IMPRIME_NIVEL			; imprime o nivel atual no canto
			goto_xy 10,20
			MOSTRA 	palavra_atual			; imprime a palavra do nivel atual
			call	IMPRIME_PONTUACAO		; transforma a pontuação em string e mostra no ecrã
			mov 	cl,concluido
			cmp 	cl,1
			je		fim					; verifica se o jogo está concluído e sai se estiver
			mov 	cx,Tempo_j
			cmp		cx,0				; verifica se o tempo de jogo já chegou ao fim
			je		fim

			
			goto_xy	78,0			; Mostra o caractr que estava na posição do AVATAR
			mov		ah, 02h			; IMPRIME caracter da posição no canto
			mov		dl, Car	
			int		21H			
	
			goto_xy	POSx,POSy		; Vai para posição do cursor
IMPRIME:	mov		ah, 02h
			mov		dl, 190			; Coloca AVATAR
			int		21H	
			goto_xy	POSx,POSy		; Vai para posição do cursor
		
			mov		al, POSx		; Guarda a posição do cursor
			mov		POSxa, al
			mov		al, POSy		; Guarda a posição do cursor
			mov 	POSya, al
		
LER_SETA:	
			call 	LE_TECLA
			cmp		ah, 1
			je		ESTEND
			CMP 	AL, 27	; ESCAPE
			JE		FIM
			jmp		LER_SETA
		
ESTEND:		cmp 	al,48h
			jne		BAIXO
			dec		POSy		;cima
			jmp		CICLO

BAIXO:		cmp		al,50h
			jne		ESQUERDA
			inc 	POSy		;Baixo
			jmp		CICLO

ESQUERDA:
			cmp		al,4Bh
			jne		DIREITA
			dec		POSx		;Esquerda
			jmp		CICLO

DIREITA:
			cmp		al,4Dh
			jne		LER_SETA 
			inc		POSx		;Direita
			jmp		CICLO

fim:
			call apaga_ecran
			mov JogoaDecorrer, 0
			call FIM_JOGO			;top10 etc
			mov concluido,0
			goto_xy 0,23
			MOSTRA TextoParaSair
			call LE_TECLA	
			cmp al,27
			jne fim
			xor ax,ax
			RET
AVATAR		endp
	

	
Main  proc
		mov			ax, dseg
		mov			ds,ax
		
		mov			ax,0B800h
		mov			es,ax
		
menu_inicial:
		xor 		ax,ax
		xor			bx,bx
		xor			cx,cx
		xor 		dx,dx
		
		call		apaga_ecran
		lea    		dx,menuFich				;Abre o Menu
		call		IMP_FICH
		
LER_SETA:		
		call 		LE_TECLA
		cmp 		ah,1
		je			estend

		cmp 		al, 27					;tecla ESC
		je			fim_programa
		
estend:	
ajuda:	
		cmp 		al, 51					;tecla 3
		jne			top10
		call		apaga_ecran
		lea    		dx,ajudaFich		;Abre a ajuda
		call		IMP_FICH
		
		call 		LE_TECLA
		cmp 		al,27
		je			menu_inicial
		
top10:	
		cmp			al, 50					;tecla 2
		jne			inicia_jogo
		call 	apaga_ecran
		goto_xy 8,0
		MOSTRA 	top10_texto
		goto_xy 0,2
		lea		dx,top10Fich
		call	IMP_FICH			; mostra no ecra o top 10
		
		goto_xy 0,12
		MOSTRA TextoParaSair
		call 		LE_TECLA
		cmp 		al,27
		je			menu_inicial

inicia_jogo:	
		cmp 		al, 49					;tecla 1
		jne			LER_SETA

		call		apaga_ecran
		lea     	dx,labiFich
									;Inicia o jogo
		call		IMP_FICH	
		call 		AVATAR
		
		jmp menu_inicial		
fim_programa:
		call apaga_ecran
		goto_xy 	0,0
		
		mov 		al, 0
		mov			ah,4CH
		INT			21H
Main	endp
cseg ends

end main