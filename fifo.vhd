library ieee;
use ieee.std_logic_1164.all;

entity fifo is
    generic (
        ADDR_WIDTH : integer := 3;
        DATA_WIDTH : integer := 8
    );
    port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        rd     : in  std_logic;
        wr     : in  std_logic;
        w_data : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        empty  : out std_logic;
        full   : out std_logic;
        r_data : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity fifo;

architecture structural of fifo is
    signal full_s   : std_logic;
    signal empty_s  : std_logic;
    signal wr_en_s  : std_logic;
    signal w_addr_s : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal r_addr_s : std_logic_vector(ADDR_WIDTH-1 downto 0);
begin
    -- La memoria no acepta escrituras cuando esta llena.
    wr_en_s <= wr and (not full_s);
    full    <= full_s;
    empty   <= empty_s;

    ctrl_unit : entity work.fifo_ctrl
        generic map (
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map (
            clk         => clk,
            reset       => reset,
            rd          => rd,
            wr          => wr,
            empty       => empty_s,
            full        => full_s,
            w_addr      => w_addr_s,
            r_addr      => r_addr_s,
            r_addr_next => open
        );

    reg_file_unit : entity work.register_file
        generic map (
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk    => clk,
            wr_en  => wr_en_s,
            w_addr => w_addr_s,
            r_addr => r_addr_s,
            w_data => w_data,
            r_data => r_data
        );
end architecture structural;
