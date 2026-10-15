library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file is
    generic (
        DATA_WIDTH : integer := 8;
        ADDR_WIDTH : integer := 3
    );
    port (
        clk    : in  std_logic;
        wr_en  : in  std_logic;
        w_addr : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        r_addr : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        w_data : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        r_data : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity register_file;

architecture rtl of register_file is
    type reg_array is array (0 to 2**ADDR_WIDTH-1) of
        std_logic_vector(DATA_WIDTH-1 downto 0);
    signal storage : reg_array;
begin
    -- Escritura sincrona en el flanco ascendente del reloj.
    process(clk)
    begin
        if rising_edge(clk) then
            if wr_en = '1' then
                storage(to_integer(unsigned(w_addr))) <= w_data;
            end if;
        end if;
    end process;

    -- Lectura asincrona: la cabeza es visible cuando empty = '0'.
    r_data <= storage(to_integer(unsigned(r_addr)));
end architecture rtl;
