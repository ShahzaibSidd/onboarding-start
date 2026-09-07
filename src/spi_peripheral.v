`default_nettype none

module spi_peripheral (
    input wire clk,
    input wire rst_n,

    input wire copi,
    input wire ncs,
    input wire sclk,

    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);

  reg [3:0] clk_counter;
  reg       transaction_ready;

  reg sclk_1, sclk_sync, sclk_prev;
  reg copi_1, copi_sync;
  reg ncs_1, ncs_sync, ncs_prev;

  wire        ncs_posedge = (!ncs_prev & ncs_sync);
  wire        sclk_posedge = (!sclk_prev & sclk_sync);

  reg  [15:0] data_in;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      clk_counter       <= 4'h0;
      transaction_ready <= 1'b0;

      sclk_1            <= 1'b0;
      sclk_sync         <= 1'b0;
      sclk_prev         <= 1'b0;

      copi_1            <= 1'b0;
      copi_sync         <= 1'b0;

      ncs_1             <= 1'b1;
      ncs_sync          <= 1'b1;
      ncs_prev          <= 1'b1;

      en_reg_out_7_0    <= 8'h00;
      en_reg_out_15_8   <= 8'h00;
      en_reg_pwm_7_0    <= 8'h00;
      en_reg_pwm_15_8   <= 8'h00;
      pwm_duty_cycle    <= 8'h00;
    end else begin
      sclk_1    <= sclk;
      sclk_sync <= sclk_1;
      sclk_prev <= sclk_sync;

      copi_1    <= copi;
      copi_sync <= copi_1;

      ncs_1     <= ncs;
      ncs_sync  <= ncs_1;
      ncs_prev  <= ncs_sync;

      if (ncs_posedge) begin
        if (transaction_ready && data_in[15]) begin
          case (data_in[14:8])
            7'd0: en_reg_out_7_0 <= data_in[7:0];
            7'd1: en_reg_out_15_8 <= data_in[7:0];
            7'd2: en_reg_pwm_7_0 <= data_in[7:0];
            7'd3: en_reg_pwm_15_8 <= data_in[7:0];
            7'd4: pwm_duty_cycle <= data_in[7:0];
            default: begin
            end
          endcase
        end
        clk_counter       <= 4'h0;
        transaction_ready <= 1'b0;
      end else if (!ncs_sync) begin
        if (sclk_posedge && !transaction_ready) begin
          data_in <= {data_in[14:0], copi_sync};

          if (clk_counter == 4'hF) begin
            transaction_ready <= 1'b1;
          end else begin
            clk_counter <= clk_counter + 1'b1;
          end
        end
      end else begin
        clk_counter       <= 4'h0;
        transaction_ready <= 1'b0;
      end
    end
  end

endmodule
