# Taller FIFO — Diseño de Sistemas Digitales

Implementación y simulación de un **buffer FIFO circular (First In, First Out)** en VHDL, desarrollada para la asignatura Diseño de Sistemas Digitales de Ingeniería Electrónica de la **Pontificia Universidad Javeriana**.

**Autor:** Sebastián Donoso  
**Herramientas utilizadas:** Quartus II 13.1 y ModelSim-Altera 13.1.

## Funcionamiento

Una FIFO conserva el orden de llegada de los datos: el primero en entrar es el primero en salir. El sistema utiliza una memoria de registros y dos apuntadores circulares:

- `w_ptr_reg`: indica dónde se escribirá el siguiente dato.
- `r_ptr_reg`: indica dónde se encuentra el dato más antiguo.

El diseño dispone de señales de control `wr` (escritura) y `rd` (lectura), y de indicadores `full` (llena) y `empty` (vacía). Las escrituras se bloquean cuando la memoria está llena; las lecturas, cuando está vacía.

| Parámetro | Valor usado |
|---|---|
| `ADDR_WIDTH` | `3` (8 posiciones) |
| `DATA_WIDTH` | `8` (8 bits por posición) |
| Período de reloj en testbench | 10 ns |
| Duración recomendada de simulación | 300 ns |

## Archivos

| Archivo | Función |
|---|---|
| `register_file.vhd` | Arreglo de registros, escritura síncrona y lectura asíncrona. |
| `fifo_ctrl.vhd` | Control de lectura/escritura, apuntadores circulares y banderas `full`/`empty`. |
| `fifo.vhd` | Entidad principal que interconecta memoria y controlador. |
| `tb_fifo.vhd` | Testbench con estímulos y verificaciones `assert`. |

## Compilación en Quartus II 13.1

1. Crear un proyecto nuevo.
2. Agregar los archivos `register_file.vhd`, `fifo_ctrl.vhd` y `fifo.vhd`.
3. Establecer **`fifo`** como *Top-Level Entity*.
4. Ejecutar **Processing → Start Compilation**.
5. Consultar **Tools → Netlist Viewers → RTL Viewer** para revisar la estructura.

> `tb_fifo.vhd` se utiliza en simulación; no es la entidad de síntesis.

## Simulación en ModelSim-Altera 13.1

Abrir ModelSim y seleccionar en **Transcript** la carpeta con los cuatro VHDL (`cd {RUTA/DE/LA/CARPETA}`). Luego ejecutar:

```tcl
if {![file isdirectory work]} { vlib work }
vmap work work
vcom register_file.vhd
vcom fifo_ctrl.vhd
vcom fifo.vhd
vcom tb_fifo.vhd
vsim work.tb_fifo
view wave
add wave -radix hexadecimal sim:/tb_fifo/w_data
add wave -radix hexadecimal sim:/tb_fifo/r_data
add wave sim:/tb_fifo/clk
add wave sim:/tb_fifo/reset
add wave sim:/tb_fifo/wr
add wave sim:/tb_fifo/rd
add wave sim:/tb_fifo/full
add wave sim:/tb_fifo/empty
add wave -radix unsigned sim:/tb_fifo/dut/ctrl_unit/w_ptr_reg
add wave -radix unsigned sim:/tb_fifo/dut/ctrl_unit/r_ptr_reg
run 300 ns
wave zoom full
```

Si vuelves a ejecutar la prueba, usa `restart -f` antes de `run 300 ns`. Evita `run -all`: el reloj del testbench continúa oscilando.

## Resultados esperados

El testbench reproduce las nueve etapas de la FIFO circular de ocho posiciones descritas en la guía, incluyendo llenado y vaciado completos. Verifica además que no se escriba en una FIFO llena ni se lea una FIFO vacía, así como operaciones simultáneas de lectura y escritura.

Al finalizar correctamente, ModelSim muestra:

```text
SIMULACION TERMINADA: todas las comprobaciones pasaron
```

La señal `r_data` no representa un dato válido mientras `empty = 1`. La advertencia inicial de `NUMERIC_STD.TO_INTEGER` puede aparecer antes de la inicialización de las direcciones; no equivale por sí misma a un fallo del testbench.

**Alcance:** simulación y revisión RTL de una FIFO síncrona de un solo reloj. No se incluyen asignaciones de pines ni pruebas físicas sobre una FPGA.
