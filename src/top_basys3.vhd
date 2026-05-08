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
    port (
        -- Standard Basys3 Ports
        clk     : in  std_logic;
        sw      : in  std_logic_vector (15 downto 0);
        btnU    : in  std_logic; -- Master Reset
        btnC    : in  std_logic; -- FSM Advance
        btnL    : in  std_logic; -- Clock Divider Reset
        led     : out std_logic_vector (15 downto 0);
        seg     : out std_logic_vector (6 downto 0);
        an      : out std_logic_vector (3 downto 0)
    );
end top_basys3;

architecture structural of top_basys3 is

    -- Component Declarations
    component ALU is
        port (
            i_A      : in  std_logic_vector(7 downto 0);
            i_B      : in  std_logic_vector(7 downto 0);
            i_op     : in  std_logic_vector(2 downto 0);
            o_result : out std_logic_vector(7 downto 0);
            o_flags  : out std_logic_vector(3 downto 0)
        );
    end component;

    component controller_fsm is
        port (
            i_clk   : in  std_logic;
            i_reset : in  std_logic;
            i_adv   : in  std_logic;
            o_cycle : out std_logic_vector(3 downto 0)
        );
    end component;

    component button_debounce is
        port (
            clk     : in  std_logic;
            reset   : in  std_logic;
            button  : in  std_logic;
            action  : out std_logic
        );
    end component;

    component clock_divider is
        generic ( k_DIV : natural := 250000 ); 
        port (
            i_clk   : in  std_logic;
            i_reset : in  std_logic;
            o_clk   : out std_logic
        );
    end component;

    component TDM4 is
        generic ( k_WIDTH : natural := 4 );
        port (
            i_clk   : in  std_logic;
            i_reset : in  std_logic;
            i_D3    : in  std_logic_vector(k_WIDTH - 1 downto 0);
            i_D2    : in  std_logic_vector(k_WIDTH - 1 downto 0);
            i_D1    : in  std_logic_vector(k_WIDTH - 1 downto 0);
            i_D0    : in  std_logic_vector(k_WIDTH - 1 downto 0);
            o_data  : out std_logic_vector(k_WIDTH - 1 downto 0);
            o_sel   : out std_logic_vector(3 downto 0)
        );
    end component;

    component sevenseg_decoder is
        port (
            i_Hex   : in  std_logic_vector(3 downto 0);
            o_seg_n : out std_logic_vector(6 downto 0)
        );
    end component;

    -- Internal Signals
    signal w_btnC_debounced : std_logic;
    signal w_clk_slow       : std_logic;
    signal w_alu_result     : std_logic_vector(7 downto 0);
    signal w_alu_flags      : std_logic_vector(3 downto 0);
    signal w_cycle          : std_logic_vector(3 downto 0);
    signal w_sel_data       : std_logic_vector(3 downto 0);

begin

    -- 1. Debounce the Advance Button
    inst_debounce: button_debounce
        port map (
            clk     => clk,
            reset   => btnU,
            button  => btnC,
            action  => w_btnC_debounced
        );

    -- 2. Instantiate FSM
    inst_fsm: controller_fsm
        port map (
            i_clk   => clk,
            i_reset => btnU,
            i_adv   => w_btnC_debounced,
            o_cycle => w_cycle
        );

    -- 3. Instantiate ALU
    inst_alu: ALU
        port map (
            i_A      => sw(15 downto 8),
            i_B      => sw(7 downto 0),
            i_op     => sw(2 downto 0), -- Typically use lower switches for opcode testing
            o_result => w_alu_result,
            o_flags  => w_alu_flags
        );

    -- 4. Clock Divider
    inst_div: clock_divider
        port map (
            i_clk   => clk,
            i_reset => btnU,
            o_clk   => w_clk_slow
        );

    -- 5. TDM4 for Multiplexing
    inst_tdm: TDM4
        port map (
            i_clk   => w_clk_slow,
            i_reset => btnU,
            i_D3    => x"0",
            i_D2    => x"0",
            i_D1    => w_alu_result(7 downto 4), -- High nibble
            i_D0    => w_alu_result(3 downto 0), -- Low nibble
            o_data  => w_sel_data,
            o_sel   => an
        );

    -- 6. Seven-Segment Decoder
    inst_seg: sevenseg_decoder
        port map (
            i_Hex   => w_sel_data,
            o_seg_n => seg
        );

    -- Output Assignments
    led(15 downto 12) <= w_alu_flags; -- NZCV
    led(3 downto 0)   <= w_cycle;     -- FSM State

end structural;
