`timescale 1ns / 1ps

module tb_i2c_master;

    // Parámetros del testbench
    localparam real CLK_PERIOD = 10.0;  // Periodo del reloj en ns (100 MHz)
    localparam logic [7:0] I2C_ADDR = 8'h90;  // Dirección del dispositivo I2C (LM75)
    localparam logic [7:0] WR_DATA = 8'h55;  // Datos para escribir
    localparam logic [7:0] RD_DATA = 8'hAA;  // Datos esperados para leer

    // Señales de prueba
    logic clk;
    logic reset;
    logic [7:0] din;
    logic [15:0] dvsr;
    logic [2:0] cmd;
    logic wr_i2c;
    tri scl;
    tri sda;
    logic ready, done_tick, ack;
    logic [7:0] dout;

    // Instancia del módulo a probar
    i2c_master uut (
        .clk(clk),
        .reset(reset),
        .din(din),
        .dvsr(dvsr),
        .cmd(cmd),
        .wr_i2c(wr_i2c),
        .scl(scl),
        .sda(sda),
        .ready(ready),
        .done_tick(done_tick),
        .ack(ack),
        .dout(dout)
    );

    // Generador de reloj
    always #(CLK_PERIOD / 2.0) clk = ~clk;

    // Tarea para resetear
    task automatic reset_task;
        begin
            reset = 1;
            @(posedge clk);
            reset = 0;
        end
    endtask

    // Tarea para escribir un byte por I2C
    task automatic i2c_write_byte(input logic [7:0] byte);
        begin
            wr_i2c = 1;
            cmd = 3'b001;  // Comando de escritura
            din = byte;
            @(posedge clk);
            wr_i2c = 0;
            wait (done_tick);
        end
    endtask

    // Tarea para leer un byte por I2C
    task automatic i2c_read_byte(output logic [7:0] byte);
        begin
            wr_i2c = 1;
            cmd = 3'b010;  // Comando de lectura
            @(posedge clk);
            wr_i2c = 0;
            wait (done_tick);
            byte = dout;
        end
    endtask

    // Inicialización y simulación
    initial begin
        // Inicialización de señales
        clk = 0;
        reset = 1;
        din = 0;
        dvsr = 16'd1000;  // Divisor para el reloj I2C (100 kHz)
        cmd = 3'b000;
        wr_i2c = 0;

        // Liberar reset
        #2 * CLK_PERIOD;
        reset = 0;

        // Simulación de operaciones I2C
        reset_task;

        // Escribir un byte
        i2c_write_byte(WR_DATA);

        // Leer un byte
        i2c_read_byte(dout);

        // Comando de parada
        @(posedge clk);
        wr_i2c = 1;
        cmd = 3'b011;  // Comando de parada
        @(posedge clk);
        wr_i2c = 0;
        wait (done_tick);

        // Verificación de resultados
        if (dout == RD_DATA) begin
            $display("Test Passed!");
        end else begin
            $display("Test Failed! Expected: %h, Got: %h", RD_DATA, dout);
        end

        // Finalización
        $finish;
    end
endmodule
