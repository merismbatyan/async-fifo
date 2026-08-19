module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
)(
    input  wire                  read_clk,
    input  wire                  write_clk,
    input  wire                  rst,

    input  wire                  read_en,
    input  wire                  write_en,

    input  wire [DATA_WIDTH-1:0] write_data,
    output wire [DATA_WIDTH-1:0] read_data,

    output wire                  empty,
    output wire                  full
);

    logic [DATA_WIDTH-1:0] memory [0:FIFO_DEPTH-1];
    //            │                     │
    //            │              FIFO_DEPTH memory locations
    //each location stores DATA_WIDTH bits

endmodule
