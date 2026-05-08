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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is
    signal w_result : std_logic_vector(8 downto 0);
begin
    process(i_A, i_B, i_op)
    begin
        case i_op is
            when "000" => -- ADD
                w_result <= std_logic_vector(resize(signed(i_A), 9) + resize(signed(i_B), 9));
            when "001" => -- SUB (A - B)
                w_result <= std_logic_vector(resize(signed(i_A), 9) - resize(signed(i_B), 9));
            when "010" => -- AND
                w_result <= ('0' & (i_A and i_B));
            when "011" => -- OR
                w_result <= ('0' & (i_A or i_B));
            when others =>
                w_result <= (others => '0');
        end case;
    end process;

    o_result <= w_result(7 downto 0);

    -- Flag Logic (NZCV)
    o_flags(3) <= w_result(7); -- N: Negative (MSB of 8-bit result)
    o_flags(2) <= '1' when w_result(7 downto 0) = x"00" else '0'; -- Z: Zero
    o_flags(1) <= w_result(8); -- C: Carry (9th bit of calculation)
    
    -- V: Signed Overflow logic
    o_flags(0) <= ((not i_A(7) and not i_B(7) and w_result(7)) or (i_A(7) and i_B(7) and not w_result(7))) when i_op = "000" else
                  ((not i_A(7) and i_B(7) and w_result(7)) or (i_A(7) and not i_B(7) and not w_result(7))) when i_op = "001" else
                  '0';
end Behavioral;