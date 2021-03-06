/*
 * 18500 Capstone S20
 * Eric Chen, Alton Olsen, Deanyone Su
 *
 * This module outputs the 4 coordinates at which a falling tetromino should be
 * rendered using the origin, type, and orientation of the falling tetromino.
 * There is no error checking in this module, this module assumes all positions
 * are valid.
 *
 * Both row and col are sized at 5-bit to accommodate 20 rows. This is following
 * pattern set by VGA module, where both row and col are 10-bit.
 *
 * Origin of each tetromino is either:
 * the center of the tile
 *      T, J, L, S, Z
 * the bottom, left tile for O and I
 */
`default_nettype none

module FallingTetrominoRender
    import  DisplayPkg::*,
            GamePkg::*;
(
    input  logic [ 4:0]     origin_row,
    input  logic [ 4:0]     origin_col,
    input  tile_type_t      falling_type,
    input  orientation_t    falling_orientation,
    output logic [ 4:0]     tile_row            [4],
    output logic [ 4:0]     tile_col            [4]
);
    always_comb begin
        case (falling_type) // has default
            I: begin
                case (falling_orientation)
                    ORIENTATION_0: begin
                        for (logic [4:0] i = 5'd0; i < 5'd4; i++) begin
                            tile_row[i] = origin_row - 5'd1;
                            tile_col[i] = origin_col + (5'd2 - i);
                        end
                    end
                    ORIENTATION_R: begin
                        for (logic [4:0] i = 5'd0; i < 5'd4; i++) begin
                            tile_row[i] = origin_row + (5'd1 - i);
                            tile_col[i] = origin_col + 5'd1;
                        end
                    end
                    ORIENTATION_2: begin
                        for (logic [4:0] i = 5'd0; i < 5'd4; i++) begin
                            tile_row[i] = origin_row;
                            tile_col[i] = origin_col + (5'd2 - i);
                        end
                    end
                    ORIENTATION_L: begin
                        for (logic [4:0] i = 5'd0; i < 5'd4; i++) begin
                            tile_row[i] = origin_row + (5'd1 - i);
                            tile_col[i] = origin_col;
                        end
                    end
                endcase
            end
            O: begin
                for (int i = 0; i < 4; i++) begin
                    tile_row[i] = origin_row - {4'd0, i[0]};
                    tile_col[i] = origin_col + {4'd0, i[1]};
                end
            end
            T: begin
                case (falling_orientation)
                    ORIENTATION_0: begin
                        tile_row[0] = origin_row;
                        tile_col[0] = origin_col;

                        tile_row[1] = origin_row;
                        tile_col[1] = origin_col - 5'd1;

                        tile_row[2] = origin_row - 5'd1;
                        tile_col[2] = origin_col;

                        tile_row[3] = origin_row;
                        tile_col[3] = origin_col + 5'd1;
                    end
                    ORIENTATION_R: begin
                        tile_row[0] = origin_row;
                        tile_col[0] = origin_col;

                        tile_row[1] = origin_row - 5'd1;
                        tile_col[1] = origin_col;

                        tile_row[2] = origin_row;
                        tile_col[2] = origin_col + 5'd1;

                        tile_row[3] = origin_row + 5'd1;
                        tile_col[3] = origin_col;
                    end
                    ORIENTATION_2: begin
                        tile_row[0] = origin_row;
                        tile_col[0] = origin_col;

                        tile_row[1] = origin_row;
                        tile_col[1] = origin_col + 5'd1;

                        tile_row[2] = origin_row + 5'd1;
                        tile_col[2] = origin_col;

                        tile_row[3] = origin_row;
                        tile_col[3] = origin_col - 5'd1;
                    end
                    ORIENTATION_L: begin
                        tile_row[0] = origin_row;
                        tile_col[0] = origin_col;

                        tile_row[1] = origin_row + 5'd1;
                        tile_col[1] = origin_col;

                        tile_row[2] = origin_row;
                        tile_col[2] = origin_col - 5'd1;

                        tile_row[3] = origin_row - 5'd1;
                        tile_col[3] = origin_col;
                    end
                endcase
            end
            J: begin
                case (falling_orientation)
                    ORIENTATION_0: begin
                        tile_row[0] = origin_row;
                        tile_col[0] = origin_col;

                        tile_row[1] = origin_row;
                        tile_col[1] = origin_col - 5'd1;

                        tile_row[2] = origin_row - 5'd1;
                        tile_col[2] = origin_col - 5'd1;

                        tile_row[3] = origin_row;
                        tile_col[3] = origin_col + 5'd1;
                    end
                    ORIENTATION_R: begin
                        tile_row[0] = origin_row;
                        tile_col[0] = origin_col;

                        tile_row[1] = origin_row - 5'd1;
                        tile_col[1] = origin_col;

                        tile_row[2] = origin_row - 5'd1;
                        tile_col[2] = origin_col + 5'd1;

                        tile_row[3] = origin_row + 5'd1;
                        tile_col[3] = origin_col;
                    end
                    ORIENTATION_2: begin
                        tile_row[0] = origin_row;
                        tile_col[0] = origin_col;

                        tile_row[1] = origin_row;
                        tile_col[1] = origin_col + 5'd1;

                        tile_row[2] = origin_row + 5'd1;
                        tile_col[2] = origin_col + 5'd1;

                        tile_row[3] = origin_row;
                        tile_col[3] = origin_col - 5'd1;
                    end
                    ORIENTATION_L: begin
                        tile_row[0] = origin_row;
                        tile_col[0] = origin_col;

                        tile_row[1] = origin_row + 5'd1;
                        tile_col[1] = origin_col;

                        tile_row[2] = origin_row + 5'd1;
                        tile_col[2] = origin_col - 5'd1;

                        tile_row[3] = origin_row - 5'd1;
                        tile_col[3] = origin_col;
                    end
                endcase
            end
            L: begin
                case (falling_orientation)
                    ORIENTATION_0: begin
                        tile_row[0] = origin_row;
                        tile_col[0] = origin_col;

                        tile_row[1] = origin_row;
                        tile_col[1] = origin_col - 5'd1;

                        tile_row[2] = origin_row - 5'd1;
                        tile_col[2] = origin_col + 5'd1;

                        tile_row[3] = origin_row;
                        tile_col[3] = origin_col + 5'd1;
                    end
                    ORIENTATION_R: begin
                        tile_row[0] = origin_row;
                        tile_col[0] = origin_col;

                        tile_row[1] = origin_row - 5'd1;
                        tile_col[1] = origin_col;

                        tile_row[2] = origin_row + 5'd1;
                        tile_col[2] = origin_col + 5'd1;

                        tile_row[3] = origin_row + 5'd1;
                        tile_col[3] = origin_col;

                    end
                    ORIENTATION_2: begin
                        tile_row[0] = origin_row;
                        tile_col[0] = origin_col;

                        tile_row[1] = origin_row;
                        tile_col[1] = origin_col + 5'd1;

                        tile_row[2] = origin_row + 5'd1;
                        tile_col[2] = origin_col - 5'd1;

                        tile_row[3] = origin_row;
                        tile_col[3] = origin_col - 5'd1;
                    end
                    ORIENTATION_L: begin
                        tile_row[0] = origin_row;
                        tile_col[0] = origin_col;

                        tile_row[1] = origin_row + 5'd1;
                        tile_col[1] = origin_col;

                        tile_row[2] = origin_row - 5'd1;
                        tile_col[2] = origin_col - 5'd1;

                        tile_row[3] = origin_row - 5'd1;
                        tile_col[3] = origin_col;
                    end
                endcase
            end
            S: begin
                case (falling_orientation)
                    ORIENTATION_0: begin
                        tile_row[0] = origin_row;
                        tile_col[0] = origin_col;

                        tile_row[1] = origin_row - 5'd1;
                        tile_col[1] = origin_col;

                        tile_row[2] = origin_row - 5'd1;
                        tile_col[2] = origin_col + 5'd1;

                        tile_row[3] = origin_row;
                        tile_col[3] = origin_col - 5'd1;
                    end
                    ORIENTATION_R: begin
                        tile_row[0] = origin_row;
                        tile_col[0] = origin_col;

                        tile_row[1] = origin_row;
                        tile_col[1] = origin_col + 5'd1;

                        tile_row[2] = origin_row + 5'd1;
                        tile_col[2] = origin_col + 5'd1;

                        tile_row[3] = origin_row - 5'd1;
                        tile_col[3] = origin_col;
                    end
                    ORIENTATION_2: begin
                        tile_row[0] = origin_row;
                        tile_col[0] = origin_col;

                        tile_row[1] = origin_row + 5'd1;
                        tile_col[1] = origin_col;

                        tile_row[2] = origin_row + 5'd1;
                        tile_col[2] = origin_col - 5'd1;

                        tile_row[3] = origin_row;
                        tile_col[3] = origin_col + 5'd1;
                    end
                    ORIENTATION_L: begin
                        tile_row[0] = origin_row;
                        tile_col[0] = origin_col;

                        tile_row[1] = origin_row;
                        tile_col[1] = origin_col - 5'd1;

                        tile_row[2] = origin_row - 5'd1;
                        tile_col[2] = origin_col - 5'd1;

                        tile_row[3] = origin_row + 5'd1;
                        tile_col[3] = origin_col;
                    end
                endcase
            end
            Z: begin
                case (falling_orientation)
                    ORIENTATION_0: begin
                        tile_row[0] = origin_row;
                        tile_col[0] = origin_col;

                        tile_row[1] = origin_row;
                        tile_col[1] = origin_col + 5'd1;

                        tile_row[2] = origin_row - 5'd1;
                        tile_col[2] = origin_col - 5'd1;

                        tile_row[3] = origin_row - 5'd1;
                        tile_col[3] = origin_col;
                    end
                    ORIENTATION_R: begin
                        tile_row[0] = origin_row;
                        tile_col[0] = origin_col;

                        tile_row[1] = origin_row + 5'd1;
                        tile_col[1] = origin_col;

                        tile_row[2] = origin_row - 5'd1;
                        tile_col[2] = origin_col + 5'd1;

                        tile_row[3] = origin_row;
                        tile_col[3] = origin_col + 5'd1;
                    end
                    ORIENTATION_2: begin
                        tile_row[0] = origin_row;
                        tile_col[0] = origin_col;

                        tile_row[1] = origin_row;
                        tile_col[1] = origin_col - 5'd1;

                        tile_row[2] = origin_row + 5'd1;
                        tile_col[2] = origin_col + 5'd1;

                        tile_row[3] = origin_row + 5'd1;
                        tile_col[3] = origin_col;
                    end
                    ORIENTATION_L: begin
                        tile_row[0] = origin_row;
                        tile_col[0] = origin_col;

                        tile_row[1] = origin_row - 5'd1;
                        tile_col[1] = origin_col;

                        tile_row[2] = origin_row + 5'd1;
                        tile_col[2] = origin_col - 5'd1;

                        tile_row[3] = origin_row;
                        tile_col[3] = origin_col - 5'd1;
                    end
                endcase
            end
            default: begin
                for (int i = 0; i < 4; i++) begin
                    tile_row[i] = 5'd0;
                    tile_col[i] = 5'd0;
                end
            end
        endcase
    end
endmodule // FallingTetrominoRender