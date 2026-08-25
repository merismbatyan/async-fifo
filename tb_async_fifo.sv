`timescale 1ns/1ps
// 1ns = simulation time unit
// 1ps = smallest precision

module tb_async_fifo;

    localparam DATA_WIDTH = 8;
    localparam FIFO_DEPTH = 16;

    logic  read_clk;
    logic  write_clk;
    logic  rst;

    logic read_en;
    logic write_en;

    logic [DATA_WIDTH-1:0] write_data;
    logic [DATA_WIDTH-1:0] read_data;

    logic empty;
    logic full;

    logic [DATA_WIDTH-1:0] expected_queue[$];
    logic [DATA_WIDTH-1:0] expected;

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .read_clk(read_clk),
        .write_clk(write_clk),
        .rst(rst),

        .read_en(read_en),
        .write_en(write_en),

        .write_data(write_data),
        .read_data(read_data),

        .empty(empty),
        .full(full)
    );

    initial begin
        write_clk = 0;

        forever begin
            #5 write_clk = ~write_clk;  // 10 ns period
        end
    end

    initial begin
        read_clk = 0;

        #3; // wait for 3 time units then start read clk to have phase difference 
        forever begin
            #7 read_clk = ~read_clk;  // 14 ns period
        end
    end

    initial begin
        rst = 1;
        read_en = 0;
        write_en = 0;
        write_data = 0;

        #20 rst = 0;
        #1;
        if (empty !== 1 || full !== 0) begin
            $error("RESET TEST FAILED: empty=%b, full=%b", empty, full);
        end
        else begin
            $display("RESET TEST PASSED");
        end
    end



    task write_fifo(input logic [DATA_WIDTH-1:0] data);
        @(negedge write_clk);                   // write on negedge so in posedge we already have data
        write_data = data;
        write_en = 1;

        @(negedge write_clk);
        write_en = 0;

        expected_queue.push_back(data);
    endtask

    task read_fifo;
        @(negedge read_clk);
        read_en = 1;

        @(negedge read_clk);
        read_en = 0;

        expected = expected_queue.pop_front();

        if (read_data !== expected) begin
            $error(
                "READ FAILED: expected=%0d, got=%0d",
                expected,
                read_data
            );
        end
        else begin
            $display(
                "READ PASSED: expected=%0d, got=%0d",
                expected,
                read_data
            );
        end
    endtask



    initial begin
        // waveform generation
        $dumpfile("async_fifo.vcd");
        $dumpvars(0, tb_async_fifo);

        wait (rst == 0);

        // basic read/write test
        $display("START BASIC WRITE/READ TEST");

        write_fifo(8'd10);
        write_fifo(8'd20);
        write_fifo(8'd30);
        write_fifo(8'd40);

        read_fifo();
        read_fifo();
        read_fifo();
        read_fifo();

        $display("BASIC WRITE/READ TEST FINISHED");

        // empty test
        @(posedge read_clk);
        @(posedge read_clk);
        @(posedge read_clk);

        if (empty !== 1) begin
            $error("EMPTY TEST FAILED");
        end
        else begin
            $display("EMPTY TEST PASSED");
        end


        //full test
        $display("START FULL TEST");

        for (int i = 0; i < FIFO_DEPTH; i++) begin
            write_fifo(i);
        end

        @(posedge write_clk);
        @(posedge write_clk);

        if (full !== 1) begin
            $error("FULL TEST FAILED");
        end
        else begin
            $display("FULL TEST PASSED");
        end


        // write when full test
        $display("START WRITE-WHEN-FULL TEST");

        @(negedge write_clk);
        write_data = 8'd99;
        write_en = 1;

        @(negedge write_clk);
        write_en = 0;

        $display("WRITE-WHEN-FULL ATTEMPT FINISHED");


        // read everything test
        $display("READING FIFO CONTENTS");

        for (int i = 0; i < FIFO_DEPTH; i++) begin
            read_fifo();
        end


        // empty after full test
        @(posedge read_clk);
        @(posedge read_clk);
        @(posedge read_clk);

        if (empty !== 1) begin
            $error("EMPTY AFTER FULL TEST FAILED");
        end
        else begin
            $display("EMPTY AFTER FULL TEST PASSED");
        end


        // read when empty test
        $display("START READ-WHEN-EMPTY TEST");

        @(negedge read_clk);
        read_en = 1;

        @(negedge read_clk);
        read_en = 0;

        $display("READ-WHEN-EMPTY ATTEMPT FINISHED");


        // simultaneous read/write test
        $display("START SIMULTANEOUS READ/WRITE TEST");

        write_fifo(8'd100);
        write_fifo(8'd101);
        write_fifo(8'd102);
        write_fifo(8'd103);

        fork // read and write at the same time

            begin
                write_fifo(8'd200);
                write_fifo(8'd201);
                write_fifo(8'd202);
                write_fifo(8'd203);
            end

            begin
                read_fifo();
                read_fifo();
                read_fifo();
                read_fifo();
            end

        join

        $display("SIMULTANEOUS READ/WRITE TEST FINISHED");

        read_fifo();
        read_fifo();
        read_fifo();
        read_fifo();


        // finiiiiiish
        $display("ALL TESTS FINISHED");

        #20;
        $finish;

    end

endmodule