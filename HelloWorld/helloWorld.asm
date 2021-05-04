; Hello World no Assembly !!!

;   Diretavas do compilador e includes

.386
.model flat, stdcall
option casemap:none                                         ; Preserva a captulação do systema


;   Include files - headers e libs que será usada para chamadas das dll dos sistema ex: user32, gdi32, kernel32, etc

include \masm32\include\windows.inc                         ; Main windows header (mesmo que Windows.h em C)
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\gdi32.inc

;   Libs - informação necessária para link do binary com as chamadas das DLL do  sistema

includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\user32.lib
includelib \masm32\lib\gdi32.lib

;   Forward declarations - Ponto de entreda chamará WinMain

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD                ; FOrward decl para MainEntry

;   Contrantes e Data

WindowWidth		equ 640
WindowHight		equ 480

.DATA
ClassName		db "MyWinClass", 0							; O nome da classe Window
AppName			db "Primeiro App em x86", 0					; O nome da tela principal

.DATA?														; data nao inicializada - reserva o espaço de endereço

hInstance		HINSTANCE ?									; Insntance handle da aplicação(como process id)
CommandLine		LPSTR ?										; Ponteiro para a linha de texto de onde o programa foi lançado

.CODE

MainEntry:

		push	NULL										; Obten a instance handle do applicativo (NULL significa o proprio aplicativo)
		call	GetModuleHandle								; GetModuleHandle retorna o instance handle no EAX
		mov		hInstance, eax								; Salva na variavel global
		
		call	GetCommandLine								; Retorna o ptr da linha de comando em EAX. Lembrar que o nome do programa retorna como primeiro argumento
		mov		CommandLine, eax
		
		; Chama o WinMain e então finaliza o processo com qualquer coisa que retorna da chamada
		
		push	SW_SHOWDEFAULT
		lea		eax, CommandLine
		push	eax
		push	NULL
		push	hInstance
		call	WinMain
		
		push	eax
		call	ExitProcess
		
;	WinMain - A assinatura paadrão para o ponto de entrada de um programa Windows

WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD

		LOCAL	wc:WNDCLASSEX								; Cria uma variavel local
		LOCAL	msg:MSG										; Não inicializa a variavel, somente aloca os endereços e vc fica com o lixo que está lá
		LOCAL	hwnd: HWND									; Precisa ser limpa manualmente
		
		mov		wc.cbSize, SIZEOF WNDCLASSEX				; Preencher os valores da "struct" windowclass
		mov		wc.style, CS_HREDRAW or CS_VREDRAW			; Flags para redimencionar a tela;
		mov		wc.lpfnWndProc, OFFSET WndProc				; Função callback para lidar com mensagens do windows
		mov		wc.cbClsExtra, 0
		mov		wc.cbWndExtra, 0
		mov		eax, hInstance								; A instance handle do nosso programa
		mov		wc.hbrBackground, COLOR_3DSHADOW+1			; Colores padrões do BRUSH = cores+1 
		mov		wc.lpszMenuName, NULL						; Sem menu
		mov		wc.lpszClassName, OFFSET ClassName			; O nome da classe da janela
		
		push	IDI_APPLICATION								; Define o icone padrão
		push	NULL										; Não precisa da instancia
		call	LoadIcon
		mov		wc.hIcon, eax
		mov		wc.hIconSm, eax
		
		push	IDC_ARROW									; Define o cursor padrão
		push	NULL
		call	LoadCursor
		mov		wc.hCursor, eax
		
		lea		eax, wc
		push	eax
		call	RegisterClassEx								; Registra a classe da janela
		
		push	NULL										; lpParam - Não temos nunhum parametro adicional
		push	hInstance									; Instance handle da aplicação
		push	NULL										; hMenu Menu handle - não usado
		push	NULL										; hWndParent Parent Window Handle - não usado
		push	WindowHight
		push	WindowWidth
		push	CW_USEDEFAULT								; Y - posição onde a tela será exibida 
		push	CW_USEDEFAULT								; X - posição onde a tela será exibida
		push	WS_OVERLAPPEDWINDOW + WS_VISIBLE			; estiplo da tela OBS: + tmb serve como bitwise or em masm
		push	OFFSET AppName								; Titulo da janela
		push	OFFSET ClassName							; nome da classe da janela
		push	0											; dwExStyle - Configs extendidas da janela
		call	CreateWindowEx
		cmp		eax, NULL									; valida se a chamada retornou um handle para a janela
		je		WinMainRet									; retorna se a chamada CreateWindowEx retornar NULL
		mov		hwnd, eax									; guarda retorno da chamada na variavel local
		
		push	eax											; Força o pintura da tela
		call	UpdateWindow
		
MessageLoop:

		push	0											; wMsgFilterMax
		push	0											; wMsgFilterMin
		push	NULL										; Mensagens da janela atual
		lea		eax, msg									; ponteiro para variavel msg loval
		push	eax
		call	GetMessage
		
		cmp		eax, 0										; quando GetMessage retornar 0 sair do loop
		je		DoneMessages
		
		lea		eax, msg
		push	eax
		call	TranslateMessage
		
		lea		eax, msg
		push	eax
		call	DispatchMessage
		
		jmp 	MessageLoop	
		
		
DoneMessages:
		mov 	eax, msg.wParam								; Retorna o wParam da ultima msg processada

WinMainRet:
		ret

WinMain endp

;	WndProc - a procedure principal, pinta a janela e exit

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

		LOCAL	ps:PAINTSTRUCT
		LOCAL	rect:RECT
		LOCAL	hdc:HDC
	
		cmp		uMsg, WM_DESTROY							; Se a msg for WM_DESTROY então sai do programa
		jne		NotWMDestroy
		
		push	0
		call	PostQuitMessage								; sai da aplicação
		xor		eax, eax									; limpa o registrador eax para 0 e retorna 0 para inform
		ret
		
NotWMDestroy:

		cmp		uMsg, WM_PAINT
		jne		NotWMPaint
		
		lea		eax, ps
		push	eax
		push	hWnd
		call	BeginPaint									; retorna o device context para ser pintado
		mov		hdc, eax
		
		push	TRANSPARENT
		push	hdc
		call	SetBkMode									; caixa de texto transparente
		
		lea 	eax, rect               					; Determina o tamanho da tela para colocar o texto no centro
		push    eax
		push    hWnd
		call    GetClientRect
 
		
		push	DT_SINGLELINE + DT_CENTER + DT_VCENTER		; format
		lea		eax, rect									; lprc
		push	eax
		push	-1											; cchText
		push	OFFSET AppName								; lpchText - o que será escrito
		push	hdc
		call	DrawText
		
		lea		eax, ps										; *lpPaint
		push	eax
		push	hWnd										; hWnd
		call	EndPaint             

		xor		eax, eax									; limpa o registrador eax para 0 e retorna 0 para inform
		ret
	
NotWMPaint:
		
		push	lParam
		push	wParam
		push	uMsg
		push	hWnd
		
		call	DefWindowProc								; Chama o tratamento defult para mensagens que não sejam WM_PAINT ou WM_DESTROY
		ret													; retora a tratativa padrão

WndProc endp

END	MainEntry												; precisa especificar o pronto de entrada se não _WinMainCRTStartup é chamado






		
