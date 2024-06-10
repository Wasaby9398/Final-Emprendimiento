### Examen Final Emprendimiento, Innovacion y Proyectos

Para este examen lo que se pide es diseñar un driver de I2C basados en el libro del doctor chu, realizar las simulaciones necesarias, hacer la comunicacion con cualquier tipo de dispositivo que tenga comunicacion i2c, realizar un cambio personalizado a este driver y por ultimo diseñar nuestro primer ASIC utilizando la plantilla de TinyTapeout

## 1 Driver I2C
Para poder realizar el driver de I2C nos centramos en realizarlo en 2 partes.
### I2C Master
Primero realizamos lo que es el archivo [I2C_Master.sv](I2C/I2C.srcs/sources_1/new/i2c_master.sv) el cual es módulo que es el encargado de manejar la comunicación directa con el bus I2C. Implementa el protocolo I2C que incluye la generación de señales de reloj (scl), la transmisión y recepción de datos (sda), y las condiciones de inicio (start) y parada (stop).

Para maneja la comunicación I2C lo hace a través de una máquina de estados finita (FSM). Acontinuacion una descripcion del flujo basado en la siguiente imagen:
![FSM](img/FSM.png)

 **1 Idle:**
El módulo está en espera hasta que se recibe un comando de inicio (START_CMD).
La señal ready está activa en este estado, indicando que el módulo está listo para recibir un comando.

**2 Start:**
La FSM genera una condición de inicio (START) en el bus I2C. Esto implica colocar la línea sda en bajo mientras scl está en alto, seguido de colocar scl en bajo.

**3 Hold:**
Preparado para la próxima operación. La FSM espera recibir un comando para proceder con una operación de lectura/escritura o generar una condición de reinicio (RESTART_CMD) o parada (STOP_CMD).

**4 Data Transfer:**
Dependiendo del comando (cmd), la FSM entra en los estados de transferencia de datos (data1 a data4). Aquí, se manejan la transmisión y recepción de datos a través de la línea sda.
Durante la escritura, se envían los bits de datos uno por uno.
Durante la lectura, se reciben los bits de datos desde el dispositivo esclavo.

**5 Data End:**
Después de completar la transferencia de datos (8 bits de datos + 1 bit de ACK/NACK), la FSM pasa al estado data_end para indicar la finalización de la transferencia de datos.

**6 Restart:**
Genera una condición de reinicio en el bus I2C.

**7 Stop:**
Genera una condición de parada (STOP) en el bus I2C.

**8 Done Tick:**
Indica la finalización de la operación actual.

Este módulo está diseñado para manejar múltiples operaciones I2C (inicio, lectura, escritura, reinicio, parada) de manera secuencial mediante el uso de una FSM.

## I2C Core
---Segundo realizamos el archivo [I2C_Core](I2C/I2C.srcs/sources_1/new/i2c_core.sv)

Este proporciona una interfaz de alto nivel para manejar las comunicaciones I2C utilizando el controlador i2c_master, permitiendo una fácil integración y control desde otros componentes del sistema.

El funcionamiento lo podemos describir:

**1 Registro del Divisor (dvsr_reg):**
Este registro se utiliza para ajustar la frecuencia del reloj del bus I2C.
Si wr_dvsr está activa (cuando cs y write están activos y la dirección addr es 0), el valor de wr_data se almacena en dvsr_reg.

**2 Decodificación de Escritura:**
wr_dvsr se activa cuando cs y write están activos y addr es 0, indicando que se debe escribir en el registro divisor.
wr_i2c se activa cuando cs y write están activos y addr es 1, indicando que se debe iniciar una operación I2C.

**3 Instancia del Módulo i2c_master:**
El módulo i2c_master se instancia y se conectan sus señales a las del módulo i2c_core.
Se le pasa el valor de wr_data para din (datos a enviar) y cmd (comando I2C), así como el divisor de reloj dvsr_reg.

**4 Lectura de Datos:**
rd_data se forma con los bits más significativos en 0 y los bits menos significativos contienen ack, ready y dout.

Con estos dos archivos ya tenemos lo necesario par aconstruir el core de nuestra comunicacion I2C, quedando este como lo siguiente:
![RTL_schematic_core](img/RTL_schematic_core.png)

## Implementacion con la Basys3

Para poder implemetar el modulo de I2C con la basys 3 se crea un nuevo archivo al cual le hemos llamado [Top.sv](I2C/I2C.srcs/sources_1/new/top.sv) el cual se encarga de integrar la comunicación I2C para leer datos de el sensor LM75 y utiliza LEDs para indicar el estado de la operación. El LED1 de la basys nos indica que hay algo en el canal de comunicacion de I2C, el LED3 nos indica si el reset esta activo o no.

Con esta implementacion ya podemos generar un nuevo esquematico donde se incluye este modulo de top:
![RTL_TOP](img/RTL_TOP.png)

Al igual que la synthesis: 
![schematic_synthesis](img/sch_synth.png)

y la Implementacion:
Donde podemos el Device:
![Device Implemetation ](img/Device_Imp.png)

Donde a su vez podemos ver los LUTs utilizados:
![LUT](img/LUT.png)

## Hardware personalizado

Para personalizar esta comunicacion I2C decidimos cambiar la trama de 8 bits a 16 bits, y tambien poner un clock de 50Mhz para el scl, para lo cual realizamos los siguientes cambios:

**Cambio de trama**
Para realziar el cambio de trama cambiamos la cantidad de bits ajustando tx_reg, tx_next, rx_reg, rx_next, a los 16 bits que queremos:

'''
    logic [16:0]  tx_reg, tx_next;
    logic [16:0]  rx_reg, rx_next; 
'''