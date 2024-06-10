module top_module (
    input  wire clk,
    input  wire reset,
    output tri  scl,
    inout  tri  sda,
    output logic  led4,
    output logic  led2
);
    // Señales internas
    logic cs, read, write;
    logic [4:0] addr;
    logic [31:0] wr_data;
    logic [31:0] rd_data;
    logic [31:0] sensor_data;

    // Instancia del I2C core
   i2c_core i2c_core_inst (
        .clk(clk),
        .reset(reset),
        .cs(cs),
        .read(read),
        .write(write),
        .addr(addr),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .scl(scl),
        .sda(sda)
    );

    // Dirección del dispositivo I2C (LM75)
    localparam [6:0] LM75_ADDR = 7'b1001000; // Dirección I2C del LM75

    // Estados para la máquina de estados
    typedef enum logic [1:0] {
        IDLE,
        READ_TEMP
    } state_t;

    state_t state, next_state;

    // Máquina de estados para la lectura del registro de temperatura
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            cs <= 0;
            read <= 0;
            write <= 0;
            addr <= 0;
            wr_data <= 0;
            led4 <= 1; // Encender led4 cuando reset está activo
        end else begin
            led4 <= 0; // Apagar led4 cuando reset está inactivo
            state <= next_state;
            case (state)
                IDLE: begin
                    // Configuración para leer el registro de temperatura
                    cs <= 1;
                    read <= 1;
                    write <= 0;
                    addr <= 4'b00000; // Dirección del registro de temperatura del LM75
                    wr_data <= {24'b0, LM75_ADDR, 1'b1}; // Dirección del dispositivo + bit de lectura
                    next_state <= READ_TEMP;
                end
                READ_TEMP: begin
                    cs <= 0;
                    read <= 0;
                    next_state <= IDLE;
                end
            endcase
        end
    end

    // Encender led5 durante cualquier comunicación I2C
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            led2 <= 0;
        end else begin
            led2 <= cs; // Enciende led5 cuando cs (chip select) está activo
        end
    end

    // Asignación de los datos leídos
    assign sensor_data = rd_data[15:0]; // Los 16 bits más bajos contienen la lectura de temperatura
endmodule

