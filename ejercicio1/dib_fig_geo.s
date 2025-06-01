.include "ref_screen.s"
.global dib_rectangulo
.global dib_ovalo_vertical

dib_rectangulo:

    /* Entrada:
        x0: dirección base de la pantalla (inicio del framebuffer)
        x1: color del rectángulo (ARGB de 32 bits)
        x2: rect_start_x (columna)
        x3: rect_start_y (fila)
        x4: rect_width (ancho del rectángulo)
        x5: rect_height (alto del rectángulo)
    */

    // Calcular el puntero al primer píxel: x3 * SCREEN_WIDTH + x2
    // tmp0 = y * SCREEN_WIDTH
    mov x6, x3                  // x6 = y
    mov x7, SCREEN_WIDTH
    mul x6, x6, x7              // x6 = y * SCREEN_WIDTH
    add x6, x6, x2              // x6 = (y * SCREEN_WIDTH + x)
    lsl x6, x6, 2               // x6 *= 4 (4 bytes por píxel)
    add x6, x0, x6              // x6 = dirección base del rectángulo

    mov x7, x5                  // x7 = rect_height (alto del rectángulo)
.rect_row_loop:
    mov x8, x4                  // x8 = rect_width (ancho del rectángulo)
    mov x9, x6                  // x9 = inicio de esta fila
.rect_col_loop:
    str w1, [x9]                // guardar color en el píxel
    add x9, x9, 4               // avanzar al siguiente píxel
    subs x8, x8, 1
    b.ne .rect_col_loop         // repetir hasta completar la fila

    add x6, x6, SCREEN_WIDTH * 4  // avanzar a la siguiente fila
    subs x7, x7, 1
    b.ne .rect_row_loop         // repetir hasta completar todas las filas

    ret


dib_ovalo_vertical:

    /* Entrada:
        x0: dirección base de la pantalla (inicio del framebuffer)
        x1: color del rectángulo (ARGB de 32 bits)
        x2: ovalo_inicio_x (columna)
        x3: ovalo_inicio_y (fila)
        x4: largo del ovalo; ancho inicial/final del ovalo
        x5: ancho creciente/decreciente del ovalo
		advertencia: x5 debe ser uno de los resultados de 2^n, 
		de lo contrario el ovalo podria no ser exacto.
    */

	// Calcula el total de una linea
	mov x11, SCREEN_WIDTH
	lsl x15, x11, 2				// x15 = SCREEN_WIDTH * 4

    // Calcular el puntero al primer píxel: x3 * SCREEN_WIDTH + x2
    // tmp0 = y * SCREEN_WIDTH
	mov x10, x3					// x10 = Y
	mul x10, x10, x11			// x10 = Y * SCREEN_WIDTH
	add x10, x10, x2			// x10 = Y * SCREEN_WIDTH + X
	lsl x10, x10, 2				// x10 = (Y * SCREEN_WIDTH + X) * 4
	add x10, x0, x10			// x10 = x0 + (Y * SCREEN_WIDTH + x) * 4
	add x0, x10, xzr			// x0 = direccion base del ovalo

	// preparativos para el loop:
	lsr x10, x4, 1				// x10 = x4/2
	lsr x11, x5, 1				// x11 = x5/2

	// preparativos para el final del loop:
	mov x12, x4					// guarda x4 en x21
	mov x13, x5					// guarda x5 en x22
	// guarda la direccion inicial en x6 y en x7
	mov x6, x0
	mov x7, x0

	// desde este punto x2 y x3 seran tratados como j e i respectivamente

	mov x3, x4					// i = x4
.ovalo_loop_o1:
	mov x2, x4					// j = x4
	cmp x3, x10					// compara i con x4/2 
	b.eq .ovalo_loop_o1_end		// si i es menor, termina el 1er loop
	cbz x11, .ovalo_loop_i2		// si x5/2 = 0, salta al segundo loopi
.ovalo_loop_i1:
	stur w1,[x0]				// colorea el pixel N
	add x0, x0, 4				// Siguiente pixel
	sub x2, x2, 1				// disminuye j
    cbnz x2, .ovalo_loop_i1		// Si no termino la fila, salta

	lsl x14, x11, 2				// x14 = x5/2 * 4
	sub x6, x6, x14				// se mueve x5/2 a la izq. del ovalo
	add x0, x15, x6				// salta a la siguiente linea
	mov x6, x0					// guarda la posicion actual de x0
	add x4, x4, x5				// aumenta el radio del ovalo
	lsr x11, x11, 1				// parte a la mitad el incremento del ovalo;
	// nota: si x11 = 1, termina siendo igal a 0
	lsr x5, x5, 1				// parte a la mitad el incremento del ovalo;
	// nota: si x4 = 1, termina siendo igal a 0
	sub x3, x3, 1				// disminuye i
	b .ovalo_loop_o1			// vuelve al inicio del 1er loop

.ovalo_loop_i2:
	stur w1,[x0]				// colorea el pixel N
	add x0, x0, 4				// Siguiente pixel
	sub x2, x2, 1				// disminuye j
    cbnz x2, .ovalo_loop_i2		// Si no termino la fila, salta

	add x0, x15, x6				// salta a la siguiente linea
	mov x6, x0					// guarda la posicion actual de x0
	sub x3, x3, 1				// disminuye i
	b .ovalo_loop_o1			// vuelve al inicio del 1er loop

.ovalo_loop_o1_end:
	mov x4, x12					// resetea x4
	mov x5, x13					// resetea x5
	mov x6, x7					// resetea x6
	lsr x11, x5, 1				// resetea x11

	mul x14, x15, x4			// x14 = Y * SCREEN_WIDTH * 4
	add x0, x6, x14				// bajo Y lineas desde la posicion inicial de x0
	mov x6, x0					// guarda la posicion actual de x0

.ovalo_loop_o2:
	mov x2, x4					// j = x4
	subs x3, x3, xzr			// veriica si i es negativo
	b.lt .ovalo_loop_o2_end		// si lo es, termina el 2do loop

.ovalo_loop_i3:
	stur w1,[x0]				// colorea el pixel N
	add x0, x0, 4				// Siguiente pixel
	sub x2, x2, 1				// disminuye j
    cbnz x2, .ovalo_loop_i3		// Si no termino la fila, salta

	lsl x14, x11, 2				// x14 = x5/2 * 4
	sub x6, x6, x14				// se mueve x5/2 a la izq. del ovalo
	sub x0, x6, x15				// salta a la linea anterior
	mov x6, x0					// guarda la posicion actual de x0
	add x4, x4, x5				// aumenta el radio del ovalo
	lsr x11, x11, 1				// parte a la mitad el incremento del ovalo;
	// nota: si x11 = 1, termina siendo igal a 0
	lsr x5, x5, 1				// parte a la mitad el incremento del ovalo;
	// nota: si x4 = 1, termina siendo igal a 0
	sub x3, x3, 1				// disminuye i
	b .ovalo_loop_o2			// vuelve al inicio del 2do loop

.ovalo_loop_i4:
	stur w1,[x0]				// colorea el pixel N
	add x0, x0, 4				// Siguiente pixel
	sub x2, x2, 1				// disminuye j
    cbnz x2, .ovalo_loop_i4		// Si x != 0, vuelve a ejejcutar
	sub x0, x6, x15				// salta a la linea anteriior
	mov x6, x0					// guarda la posicion actual de x0
	sub x3, x3, 1				// disminuye i
	b .ovalo_loop_o2			// vuelve al inicio del loopo
.ovalo_loop_o2_end:

    ret
