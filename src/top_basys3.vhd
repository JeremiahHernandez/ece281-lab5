--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        btnL    :   in std_logic;
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 

    -- Component Declarations
    component controller_fsm is
        port (
            i_clk   : in  std_logic;
            i_reset : in  std_logic;
            i_adv   : in  std_logic;
            o_cycle : out std_logic_vector(3 downto 0)
        );
    end component;

    component ALU is
        port (
            i_A      : in  std_logic_vector(7 downto 0);
            i_B      : in  std_logic_vector(7 downto 0);
            i_op     : in  std_logic_vector(2 downto 0);
            o_result : out std_logic_vector(7 downto 0);
            o_flags  : out std_logic_vector(3 downto 0)
        );
    end component;

    component twos_comp is
        port (
            i_bin  : in  std_logic_vector(7 downto 0);
            o_sign : out std_logic;
            o_hund : out std_logic_vector(3 downto 0);
            o_tens : out std_logic_vector(3 downto 0);
            o_ones : out std_logic_vector(3 downto 0)
        );
    end component;

    component TDM4 is
        generic ( k_WIDTH : natural  := 4 );
        port ( i_clk        : in  std_logic;
               i_reset      : in  std_logic;
               i_D3         : in  std_logic_vector (k_WIDTH - 1 downto 0);
               i_D2         : in  std_logic_vector (k_WIDTH - 1 downto 0);
               i_D1         : in  std_logic_vector (k_WIDTH - 1 downto 0);
               i_D0         : in  std_logic_vector (k_WIDTH - 1 downto 0);
               o_data       : out std_logic_vector (k_WIDTH - 1 downto 0);
               o_sel        : out std_logic_vector (3 downto 0)
        );
    end component;

    component sevenseg_decoder is
        port ( i_Hex   : in  std_logic_vector (3 downto 0);
               o_seg_n : out std_logic_vector (6 downto 0));
    end component;

    component clock_divider is
        generic ( k_DIV : natural := 2 );
        port ( i_clk   : in  std_logic;
               i_reset : in  std_logic;
               o_clk   : out std_logic
        );
    end component;

    -- Signals
    signal w_clk_tdm : std_logic;
    signal w_cycle   : std_logic_vector(3 downto 0);
    signal w_op1, w_op2, w_alu_res, w_mux_out : std_logic_vector(7 downto 0);
    signal w_flags   : std_logic_vector(3 downto 0);
    signal w_sign, w_hund, w_tens, w_ones, w_dec_in : std_logic_vector(3 downto 0);
    signal w_sel_an  : std_logic_vector(3 downto 0);
    signal w_sign_bit : std_logic;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if btnU = '1' then
                w_op1 <= (others => '0');
                w_op2 <= (others => '0');
            elsif w_cycle = "0010" then
                w_op1 <= sw;
            elsif w_cycle = "0100" then
                w_op2 <= sw;
            end if;
        end if;
    end process;

    w_mux_out <= w_op1     when w_cycle = "0010" else
                 w_op2     when w_cycle = "0100" else
                 w_alu_res when w_cycle = "1000" else
                 x"00";

    -- Port Maps
    u_fsm : controller_fsm port map (
        i_clk   => clk,
        i_reset => btnU,
        i_adv   => btnC,
        o_cycle => w_cycle
    );

    u_alu : ALU port map (
        i_A      => w_op1,
        i_B      => w_op2,
        i_op     => sw(2 downto 0),
        o_result => w_alu_res,
        o_flags  => w_flags
    );

    u_twos : twos_comp port map (
    i_bin  => w_mux_out,
    o_sign => w_sign_bit,
    o_hund => w_hund,
    o_tens => w_tens,
    o_ones => w_ones
);

    u_clkdiv : clock_divider 
        generic map ( k_DIV => 50000 )
        port map ( i_clk => clk, i_reset => btnL, o_clk => w_clk_tdm );

    u_tdm : TDM4 port map (
        i_clk => w_clk_tdm, i_reset => btnU,
        i_D3 => w_sign, i_D2 => w_hund, i_D1 => w_tens, i_D0 => w_ones,
        o_data => w_dec_in, o_sel => w_sel_an
    );

    u_seg : sevenseg_decoder port map (
        i_Hex => w_dec_in, o_seg_n => seg
    );

    led(3 downto 0)   <= w_cycle;
    led(15 downto 12) <= w_flags; 
    led(11 downto 4)  <= (others => '0');

    an <= "1111" when w_cycle = "0001" else w_sel_an;

end top_basys3_arch;
