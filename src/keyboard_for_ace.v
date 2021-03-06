`timescale 1ns / 1ps
`default_nettype none

module keyboard_for_ace(
    input wire clk,
    input wire [10:0] ps2_key,
    input wire [7:0] rows,
    output wire [4:0] columns,
    output reg kbd_reset,
    output reg kbd_nmi,
    output reg kbd_mreset,
    output [7:0] led
    );

    initial begin
        kbd_reset = 1'b1;
        kbd_nmi = 1'b1;
        kbd_mreset = 1'b1;
    end

    `include "keyboard_map_uk.vh"

    wire [10:0] ps2_key;
    wire new_key_aval = ps2_key[10];
    wire [7:0] scancode = ps2_key[7:0];
    wire is_released = ps2_key[9];
    wire is_extended = ps2_key[8];

    reg shift_pressed = 1'b0;
    reg ctrl_pressed = 1'b0;
    reg alt_pressed = 1'b0;
    
    reg [4:0] matrix[0:7];  // 40-key matrix keyboard
    initial begin
        matrix[0] <= 5'b11111;  // C X Z SS CS
        matrix[1] <= 5'b11111;  // G F D S A
        matrix[2] <= 5'b11111;  // T R E W Q
        matrix[3] <= 5'b11111;  // 5 4 3 2 1
        matrix[4] <= 5'b11111;  // 6 7 8 9 0
        matrix[5] <= 5'b11111;  // Y U I O P
        matrix[6] <= 5'b11111;  // H J K L ENT
        matrix[7] <= 5'b11111;  // V B N M SP
    end

    assign columns = (matrix[0] | { {8{rows[0]}} }) &
                     (matrix[1] | { {8{rows[1]}} }) &
                     (matrix[2] | { {8{rows[2]}} }) &
                     (matrix[3] | { {8{rows[3]}} }) &
                     (matrix[4] | { {8{rows[4]}} }) &
                     (matrix[5] | { {8{rows[5]}} }) &
                     (matrix[6] | { {8{rows[6]}} }) &
                     (matrix[7] | { {8{rows[7]}} });

    always @(posedge clk) begin
        if (new_key_aval == 1'b1) begin
            case (scancode)
                // Special and control keys
                `KEY_LSHIFT,
                `KEY_RSHIFT:
                    shift_pressed <= ~is_released;
                `KEY_LCTRL,
                `KEY_RCTRL:
                    begin
                        ctrl_pressed <= ~is_released;
                        if (is_extended)
                            matrix[0][1] <= is_released;  // Right control = Symbol shift
                        else
                            matrix[0][0] <= is_released;  // Left control = Caps shift
                    end
                `KEY_LALT:
                    alt_pressed <= ~is_released;
                `KEY_KPPUNTO:
                    if (ctrl_pressed && alt_pressed) begin
                        kbd_reset <= is_released;
                        if (is_released == 1'b0) begin
                            matrix[0] <= 5'b11111;  // C X Z SS CS
                            matrix[1] <= 5'b11111;  // G F D S A
                            matrix[2] <= 5'b11111;  // T R E W Q
                            matrix[3] <= 5'b11111;  // 5 4 3 2 1
                            matrix[4] <= 5'b11111;  // 6 7 8 9 0
                            matrix[5] <= 5'b11111;  // Y U I O P
                            matrix[6] <= 5'b11111;  // H J K L ENT
                            matrix[7] <= 5'b11111;  // V B N M SP
                        end
                    end                            
                `KEY_F5:
                    if (ctrl_pressed && alt_pressed)
                        kbd_nmi <= is_released;
                `KEY_ENTER:
                    matrix[6][0] <= is_released;
                `KEY_ESC:
                    begin
                        matrix[0][0] <= is_released;
                        matrix[7][0] <= is_released;
                    end
                `KEY_BKSP:
                    if (ctrl_pressed && alt_pressed) begin
                        kbd_mreset <= is_released;                        
                    end
                    else begin
                        matrix[0][0] <= is_released;
                        matrix[4][0] <= is_released;
                    end
                `KEY_CPSLK:
                    begin
                        matrix[0][0] <= is_released;
                        matrix[3][1] <= is_released;  // CAPS LOCK
                    end
                `KEY_F2:
                    begin
                        matrix[0][0] <= is_released;
                        matrix[3][0] <= is_released;  // EDIT
                    end
                        
                // Digits and puntuaction marks inside digits
                `KEY_1:
                    begin
                        if (alt_pressed) begin
                            matrix[0][1] <= is_released;
                            matrix[1][1] <= is_released;  // |
                        end
                        else if (shift_pressed) begin
                            matrix[0][1] <= is_released;
                            matrix[3][0] <= is_released;  // !
                        end
                        else
                            matrix[3][0] <= is_released;
                        
                    end
                `KEY_2:
                    begin
                        if (alt_pressed) begin
                            matrix[0][1] <= is_released;
                            matrix[3][1] <= is_released;  // @
                        end
                        else if (shift_pressed) begin
                            matrix[0][1] <= is_released;
                            matrix[5][0] <= is_released;  // "
                        end
                        else
                            matrix[3][1] <= is_released;
                    end
                `KEY_3:
                    begin
                        if (!shift_pressed)
                            matrix[3][2] <= is_released;
                        else begin
                            matrix[0][1] <= is_released;
                            matrix[0][3] <= is_released;  // £
                        end
                    end
                `KEY_4:
                    begin
                        if (shift_pressed) begin
                            matrix[0][1] <= is_released;
                            matrix[3][3] <= is_released;  // $
                        end
                        else if (ctrl_pressed) begin
                            matrix[0][0] <= is_released;
                            matrix[3][3] <= is_released; // INV VIDEO
                        end
                        else
                            matrix[3][3] <= is_released;                        
                    end
                `KEY_5:
                    begin
                        if (!shift_pressed)
                            matrix[3][4] <= is_released;
                        else begin
                            matrix[0][1] <= is_released;
                            matrix[3][4] <= is_released;  // %
                        end
                    end
                `KEY_6:
                    begin
                        if (!shift_pressed)
                            matrix[4][4] <= is_released;
                        else begin
                            matrix[0][1] <= is_released;
                            matrix[6][4] <= is_released;  // ^
                        end
                    end
                `KEY_7:
                    begin
                        if (!shift_pressed)
                            matrix[4][3] <= is_released;
                        else begin
                            matrix[0][1] <= is_released;
                            matrix[4][4] <= is_released;  // &
                        end
                    end
                `KEY_8:
                    begin
                        if (!shift_pressed)
                            matrix[4][2] <= is_released;
                        else begin
                            matrix[0][1] <= is_released;
                            matrix[7][3] <= is_released;  // *
                        end
                    end
                `KEY_9:
                    begin
                        if (shift_pressed) begin
                            matrix[0][1] <= is_released;
                            matrix[4][2] <= is_released;  // (
                        end
                        else if (ctrl_pressed) begin
                            matrix[0][0] <= is_released;
                            matrix[4][2] <= is_released;
                        end
                        else
                            matrix[4][1] <= is_released;
                    end
                `KEY_0:
                    begin
                        if (!shift_pressed)
                            matrix[4][0] <= is_released;
                        else begin
                            matrix[0][1] <= is_released;
                            matrix[4][1] <= is_released;  // )
                        end
                    end
                    
                // Alphabetic characters
                `KEY_Z:
                    begin
                        matrix[0][2] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_X:
                    begin
                        matrix[0][3] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_C:
                    begin
                        matrix[0][4] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_A:
                    begin
                        matrix[1][0] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_S:
                    begin
                        matrix[1][1] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_D:
                    begin
                        matrix[1][2] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_F:
                    begin
                        matrix[1][3] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_G:
                    begin
                        matrix[1][4] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_Q:
                    begin
                        matrix[2][0] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_W:
                    begin
                        matrix[2][1] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_E:
                    begin
                        matrix[2][2] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_R:
                    begin
                        matrix[2][3] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_T:
                    begin
                        matrix[2][4] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_P:
                    begin
                        matrix[5][0] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_O:
                    begin
                        matrix[5][1] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_I:
                    begin
                        matrix[5][2] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_U:
                    begin
                        matrix[5][3] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_Y:
                    begin
                        matrix[5][4] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_L:
                    begin
                        matrix[6][1] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_K:
                    begin
                        matrix[6][2] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_J:
                    begin
                        matrix[6][3] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_H:
                    begin
                        matrix[6][4] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_M:
                    begin
                        matrix[7][1] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_N:
                    begin
                        matrix[7][2] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_B:
                    begin
                        matrix[7][3] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_V:
                    begin
                        matrix[7][4] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                    
                // Symbols
                `KEY_APOS:
                    begin
                        matrix[0][1] <= is_released;
                        if (!shift_pressed)
                            matrix[4][3] <= is_released; // '
                        else
                            matrix[3][1] <= is_released;  // @
                    end
                `KEY_AEXC:
                    begin
                        matrix[0][1] <= is_released;
                        if (!shift_pressed)
                            matrix[6][1] <= is_released;  // =
                        else
                            matrix[6][2] <= is_released;  // +
                    end
		`KEY_KPSLASH:
		    begin
                        matrix[0][1] <= is_released;
                        if (!shift_pressed)
                            matrix[7][4] <= is_released;  // /
                        else
                            matrix[0][4] <= is_released;  // ?
                    end
                `KEY_CORCHA:
                    begin
                        matrix[0][1] <= is_released;
                        if (alt_pressed || shift_pressed)
                            matrix[1][3] <= is_released;  // {
                        else
                            matrix[5][4] <= is_released;  // [
                    end
                `KEY_CORCHC:
                    begin
                        matrix[0][1] <= is_released;
                        if (alt_pressed || shift_pressed)
                            matrix[1][4] <= is_released;  // {
                        else
                            matrix[5][3] <= is_released;  // ]
                    end
                `KEY_LLAVC:
                    begin
                        matrix[0][1] <= is_released;
                        matrix[5][2] <= is_released;  // copyright
                    end
                `KEY_NT:
                    begin
                        matrix[0][1] <= is_released;
                        if (!shift_pressed)
                            matrix[5][1] <= is_released;  // ;
                        else
                            matrix[0][2] <= is_released;  // :
                    end
                `KEY_COMA:
                    begin
                        matrix[0][1] <= is_released;
                        if (!shift_pressed)
                            matrix[7][2] <= is_released;  // ,
                        else
                            matrix[2][3] <= is_released;  // <
                    end
                `KEY_PUNTO:
                    begin
                        matrix[0][1] <= is_released;
                        if (!shift_pressed)
                            matrix[7][1] <= is_released;  // .
                        else
                            matrix[2][4] <= is_released;  // >
                    end
                `KEY_MENOS:
                    begin
                        matrix[0][1] <= is_released;
                        if (!shift_pressed)
                            matrix[6][3] <= is_released;  // -
                        else
                            matrix[4][0] <= is_released;  // _
                    end
                `KEY_LT:
                    begin
                        matrix[0][1] <= is_released;
                        if (!shift_pressed)
                            matrix[1][2] <= is_released;  // <
                        else
                            matrix[1][1] <= is_released;  // >
                    end
                `KEY_BL:
                    begin
                        matrix[0][1] <= is_released;
                        if (!shift_pressed)
                            matrix[3][2] <= is_released;  // £
                        else
                            matrix[1][0] <= is_released;  // ~
                    end       
                `KEY_SPACE:
                    matrix[7][0] <= is_released;
                    
                // Cursor keys
                `KEY_UP:
                    begin
                        matrix[0][0] <= is_released;
                        matrix[4][4] <= is_released;
                    end
                `KEY_DOWN:
                    begin
                        matrix[0][0] <= is_released;
                        matrix[4][3] <= is_released;
                    end
                `KEY_LEFT:
                    begin
                        matrix[0][0] <= is_released;
                        matrix[3][4] <= is_released;
                    end
                `KEY_RIGHT:
                    begin
                        matrix[0][0] <= is_released;
                        matrix[4][2] <= is_released;
                    end
            endcase    
        end
    end
endmodule
