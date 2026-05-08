----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
    Port ( 
        i_A      : in  STD_LOGIC_VECTOR (7 downto 0);
        i_B      : in  STD_LOGIC_VECTOR (7 downto 0);
        i_op     : in  STD_LOGIC_VECTOR (2 downto 0);
        o_result : out STD_LOGIC_VECTOR (7 downto 0);
        o_flags  : out STD_LOGIC_VECTOR (3 downto 0) -- NZCV
    );
end ALU;

architecture Behavioral of ALU is
    -- Internal 9-bit signal to capture carry/borrow out
    signal w_result : std_logic_vector(8 downto 0);
begin

    -- Combinational Process for ALU Operations
    process(i_A, i_B, i_op)
    begin
        case i_op is
            when "000" => -- ADD
                w_result <= std_logic_vector(resize(unsigned(i_A), 9) + resize(unsigned(i_B), 9));
            
            when "001" => -- SUB (A - B)
                w_result <= std_logic_vector(resize(unsigned(i_A), 9) - resize(unsigned(i_B), 9));
            
            when "010" => -- AND
                w_result <= ('0' & (i_A and i_B));
            
            when "011" => -- OR
                w_result <= ('0' & (i_A or i_B));
            
            when others =>
                w_result <= (others => '0');
        end case;
    end process;

    -- Output Assignment
    o_result <= w_result(7 downto 0);

    ----------------------------------------------------------------------------
    -- FLAG LOGIC (NZCV)
    ----------------------------------------------------------------------------
    
    -- N (Negative): Set if the result MSB is 1
    o_flags(3) <= w_result(7);

    -- Z (Zero): Set if the 8-bit result is exactly zero
    o_flags(2) <= '1' when w_result(7 downto 0) = x"00" else '0';

    -- C (Carry): The 9th bit of the calculation. 
    -- For ADD, it is the Carry. For SUB, it represents the Borrow.
    o_flags(1) <= w_result(8);

    -- V (Overflow): Logic for signed arithmetic
    -- Set when the sign of the result is incorrect based on the input signs.
    o_flags(0) <= ((not i_A(7) and not i_B(7) and w_result(7)) or 
                  (i_A(7) and i_B(7) and not w_result(7))) when i_op = "000" else -- Addition
                  ((not i_A(7) and i_B(7) and w_result(7)) or 
                  (i_A(7) and not i_B(7) and not w_result(7))) when i_op = "001" else -- Subtraction
                  '0'; -- Logic operations do not produce overflow

end Behavioral;