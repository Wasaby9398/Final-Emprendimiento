module uart_tx (
    input  wire clk,
    input  wire reset,
    input  wire [31:0] sensor_data,
    output reg  tx
);
    // Parámetros de configuración UART
    parameter BAUD_RATE = 9600;
    parameter CLOCK_FREQ = 100_000_000; // Frecuencia del reloj en Hz

    // Contadores para la generación del baud rate
    reg [15:0] baud_counter = 0;
    reg [3:0] bit_counter = 0;
    reg [31:0] data_reg;

    // Generación de la señal de baud rate
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            baud_counter <= 0;
            bit_counter <= 0;
        end else begin
            if (baud_counter == CLOCK_FREQ / BAUD_RATE / 2 - 1) begin
                baud_counter <= 0;
                bit_counter <= bit_counter + 1;
                if (bit_counter == 9) begin
                    bit_counter <= 0;
                    tx <= 1; // Bit de parada
                end else begin
                    tx <= data_reg[bit_counter];
                end
            end else begin
                baud_counter <= baud_counter + 1;
            end
        end
    end

    // Proceso para enviar datos por UART
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_reg <= 0;
        end else begin
            data_reg <= sensor_data;
        end
    end
endmodule
