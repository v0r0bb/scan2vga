module scan2vga_top #(
    parameter CLK_FREQ_HZ = 50_000_000,
    parameter BAUD_RATE   = 115200,

    parameter LIDAR_MAX_MM = 8000,
    parameter LIDAR_MIN_MM = 130,

    parameter TARGET_RPM  = 360,
    parameter PWM_WIDTH   = 8,
    parameter PWM_FREQ_HZ = 10_000
) (
    input  clk_i,
    input  rst_n,

    input lidar_rx_i,

    output motor_pwm_o
    // output motor_in1_o,
    // output motor_in2_o,

    // output tx_o
    // output [7:0]  vga_r_o, vga_g_o, vga_b_o,
    // output        vga_hsync_o, vga_fsync_o, vga_srtobe_o,
    // output        vga_blank_n_o, vga_sync_n_o
);

endmodule
