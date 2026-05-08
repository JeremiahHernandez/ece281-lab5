----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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

entity controller_fsm is
    Port ( i_clk   : in  STD_LOGIC;
           i_reset : in  STD_LOGIC;
           i_adv   : in  STD_LOGIC; -- Debounced pulse from btnC
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is

    type state_type is (s_reset, s_op1, s_op2, s_result);
    signal r_state : state_type := s_reset;

begin

    process(i_clk, i_reset)
    begin
        if (i_reset = '1') then
            r_state <= s_reset;
        elsif (rising_edge(i_clk)) then
            -- Only advance if the button is pressed (debounced pulse)
            if (i_adv = '1') then
                case r_state is
                    when s_reset =>
                        r_state <= s_op1;
                    when s_op1 =>
                        r_state <= s_op2;
                    when s_op2 =>
                        r_state <= s_result;
                    when s_result =>
                        r_state <= s_op1; -- Usually loops back to op1, not reset
                    when others =>
                        r_state <= s_reset;
                end case;
            end if;
        end if;
    end process;

    o_cycle <= "0001" when r_state = s_reset else
               "0010" when r_state = s_op1   else
               "0100" when r_state = s_op2   else
               "1000" when r_state = s_result else
               "0001"; -- Default to reset state

end FSM;
