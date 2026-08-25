module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
)(
    input  wire                   read_clk,
    input  wire                   write_clk,
    input  wire                   rst,
 
    input  wire                   read_en,
    input  wire                   write_en,

    input  wire  [DATA_WIDTH-1:0] write_data,
    output logic [DATA_WIDTH-1:0] read_data,

    output wire                   empty,
    output wire                   full
);

    logic [DATA_WIDTH-1:0] memory [0:FIFO_DEPTH-1];
    //            │                     │
    //            │              FIFO_DEPTH memory locations
    //each location stores DATA_WIDTH bits

    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);
    logic [1 + (ADDR_WIDTH-1):0] write_ptr;
    logic [1 + (ADDR_WIDTH-1):0] read_ptr;
    //     │              │
    //     │         FIFO_DEPTH memory locations
    // 1 extra bit to detect full/empty conditions (wrap around)

    // used to deal with crossing clock domains
    logic [1 + (ADDR_WIDTH-1):0] write_ptr_gray;
    logic [1 + (ADDR_WIDTH-1):0] read_ptr_gray;

    assign write_ptr_gray = write_ptr ^ (write_ptr >> 1);
    assign read_ptr_gray = read_ptr ^ (read_ptr >> 1);

    always_ff @(posedge write_clk or posedge rst) begin
        if (rst) begin
            write_ptr <= 0;
        end 
        else if (write_en && !full) begin
            memory[write_ptr[ADDR_WIDTH-1:0]] <= write_data;
            //                     |
            //      first bit is for wrap detection, rest are memory address bits
            write_ptr <= write_ptr + 1;
        end
    end

    always_ff @(posedge read_clk or posedge rst) begin
        if (rst) begin
            read_ptr <= 0;
        end 
        else if (read_en && !empty) begin
            read_data <= memory[read_ptr[ADDR_WIDTH-1:0]];
            //                                  |
            //      first bit is for wrap detection, rest are memory address bits
            read_ptr <= read_ptr + 1;
        end
    end

    // sync pointers for clock domain crossing
    logic [1 + (ADDR_WIDTH-1):0] write_ptr_gray_sync1;
    logic [1 + (ADDR_WIDTH-1):0] write_ptr_gray_sync2;
    logic [1 + (ADDR_WIDTH-1):0] read_ptr_gray_sync1;
    logic [1 + (ADDR_WIDTH-1):0] read_ptr_gray_sync2;

    always_ff @(posedge read_clk or posedge rst) begin
        if (rst) begin
            write_ptr_gray_sync1 <= 0;
            write_ptr_gray_sync2 <= 0;
        end
        else begin
            write_ptr_gray_sync1 <= write_ptr_gray;
            write_ptr_gray_sync2 <= write_ptr_gray_sync1;
        end
    end

    always_ff @(posedge write_clk or posedge rst) begin
        if (rst) begin
            read_ptr_gray_sync1 <= 0;
            read_ptr_gray_sync2 <= 0;
        end
        else begin
            read_ptr_gray_sync1 <= read_ptr_gray;
            read_ptr_gray_sync2 <= read_ptr_gray_sync1;
        end
    end

    assign empty = (read_ptr_gray == write_ptr_gray_sync2);
    //   read = 000       write = 100  - binary
    //   read = 000       write = 110  - gray    => first 2 bits inverted
    assign full = (write_ptr_gray == {~read_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], read_ptr_gray_sync2[ADDR_WIDTH-2:0]});
endmodule
