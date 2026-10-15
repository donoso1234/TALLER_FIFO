library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_ctrl is
    generic (
        ADDR_WIDTH : natural := 3
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        rd          : in  std_logic;
        wr          : in  std_logic;
        empty       : out std_logic;
        full        : out std_logic;
        w_addr      : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        r_addr      : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        r_addr_next : out std_logic_vector(ADDR_WIDTH-1 downto 0)
    );
end entity fifo_ctrl;

architecture arch of fifo_ctrl is
    signal w_ptr_reg, w_ptr_next, w_ptr_succ :
        std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal r_ptr_reg, r_ptr_next, r_ptr_succ :
        std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal full_reg, full_next   : std_logic;
    signal empty_reg, empty_next : std_logic;
    signal wr_op                : std_logic_vector(1 downto 0);
begin
    -- Registros de punteros y banderas.
    process(clk, reset)
    begin
        if reset = '1' then
            w_ptr_reg <= (others => '0');
            r_ptr_reg <= (others => '0');
            full_reg  <= '0';
            empty_reg <= '1';
        elsif rising_edge(clk) then
            w_ptr_reg <= w_ptr_next;
            r_ptr_reg <= r_ptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end if;
    end process;

    -- Los punteros avanzan circularmente (7 -> 0 para 8 posiciones).
    w_ptr_succ <= std_logic_vector(unsigned(w_ptr_reg) + 1);
    r_ptr_succ <= std_logic_vector(unsigned(r_ptr_reg) + 1);

    -- Combinaciones: 00 ninguna; 01 leer; 10 escribir; 11 ambas.
    wr_op <= wr & rd;

    process(w_ptr_reg, w_ptr_succ, r_ptr_reg, r_ptr_succ,
            wr_op, empty_reg, full_reg)
    begin
        -- Por defecto, conservar estado.
        w_ptr_next <= w_ptr_reg;
        r_ptr_next <= r_ptr_reg;
        full_next  <= full_reg;
        empty_next <= empty_reg;

        case wr_op is
            when "00" =>
                null;

            when "01" =>  -- Solo lectura.
                if empty_reg = '0' then
                    r_ptr_next <= r_ptr_succ;
                    full_next  <= '0';
                    if r_ptr_succ = w_ptr_reg then
                        empty_next <= '1';
                    end if;
                end if;

            when "10" =>  -- Solo escritura.
                if full_reg = '0' then
                    w_ptr_next <= w_ptr_succ;
                    empty_next <= '0';
                    if w_ptr_succ = r_ptr_reg then
                        full_next <= '1';
                    end if;
                end if;

            when others => -- Lectura y escritura simultaneas.
                if empty_reg = '1' then
                    -- Si esta vacia, se acepta solo la escritura.
                    w_ptr_next <= w_ptr_succ;
                    empty_next <= '0';
                    full_next  <= '0';
                elsif full_reg = '1' then
                    -- Si esta llena, se acepta solo la lectura.
                    r_ptr_next <= r_ptr_succ;
                    full_next  <= '0';
                    empty_next <= '0';
                else
                    -- En estado intermedio, una lectura y una escritura.
                    w_ptr_next <= w_ptr_succ;
                    r_ptr_next <= r_ptr_succ;
                end if;
        end case;
    end process;

    w_addr      <= w_ptr_reg;
    r_addr      <= r_ptr_reg;
    r_addr_next <= r_ptr_next;
    full        <= full_reg;
    empty       <= empty_reg;
end architecture arch;
