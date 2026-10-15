library ieee;
use ieee.std_logic_1164.all;

entity tb_fifo is
end entity tb_fifo;

architecture sim of tb_fifo is
    constant CLK_PERIOD : time := 10 ns;

    signal clk    : std_logic := '0';
    signal reset  : std_logic := '1';
    signal rd     : std_logic := '0';
    signal wr     : std_logic := '0';
    signal w_data : std_logic_vector(7 downto 0) := (others => '0');
    signal r_data : std_logic_vector(7 downto 0);
    signal empty  : std_logic;
    signal full   : std_logic;
begin
    clk <= not clk after CLK_PERIOD/2;

    dut : entity work.fifo
        generic map (
            ADDR_WIDTH => 3, -- 2**3 = 8 posiciones.
            DATA_WIDTH => 8
        )
        port map (
            clk    => clk,
            reset  => reset,
            rd     => rd,
            wr     => wr,
            w_data => w_data,
            empty  => empty,
            full   => full,
            r_data => r_data
        );

    stimulus : process
        -- Aplica una operacion durante un flanco de reloj.
        procedure paso(
            constant escritura : in std_logic;
            constant lectura   : in std_logic;
            constant dato      : in std_logic_vector(7 downto 0)
        ) is
        begin
            wait until falling_edge(clk);
            wr     <= escritura;
            rd     <= lectura;
            w_data <= dato;
            wait until rising_edge(clk);
            wait for 1 ns;
            wr <= '0';
            rd <= '0';
        end procedure;
    begin
        -- Estado (a): reset, FIFO vacia.
        wait for 12 ns;
        reset <= '0';
        wait for 1 ns;
        assert (empty = '1' and full = '0')
            report "ERROR: reset inicial" severity error;

        -- (b) Una escritura: 11.
        paso('1', '0', x"11");
        assert (empty = '0' and full = '0' and r_data = x"11")
            report "ERROR: primera escritura" severity error;

        -- (c) Tres escrituras adicionales: 22, 33, 44.
        paso('1', '0', x"22");
        paso('1', '0', x"33");
        paso('1', '0', x"44");
        assert (r_data = x"11" and full = '0')
            report "ERROR: tres escrituras adicionales" severity error;

        -- (d) Una lectura: se retira 11; ahora se ve 22.
        paso('0', '1', x"00");
        assert (r_data = x"22" and empty = '0')
            report "ERROR: primera lectura" severity error;

        -- (e) Cuatro escrituras: 55, 66, 77, 88.
        paso('1', '0', x"55");
        paso('1', '0', x"66");
        paso('1', '0', x"77");
        paso('1', '0', x"88");
        assert (r_data = x"22" and full = '0')
            report "ERROR: cuatro escrituras" severity error;

        -- (f) Una escritura mas: 99; FIFO llena (8 elementos).
        paso('1', '0', x"99");
        assert (full = '1' and empty = '0' and r_data = x"22")
            report "ERROR: FIFO no marco full" severity error;

        -- Comprobacion extra: escritura bloqueada por full.
        paso('1', '0', x"AA");
        assert (full = '1' and r_data = x"22")
            report "ERROR: escritura permitida estando llena" severity error;

        -- (g) Dos lecturas: se retiran 22 y 33; ahora se ve 44.
        paso('0', '1', x"00");
        paso('0', '1', x"00");
        assert (full = '0' and r_data = x"44")
            report "ERROR: dos lecturas" severity error;

        -- (h) Cinco lecturas: quedan solo 99.
        paso('0', '1', x"00"); -- retira 44
        paso('0', '1', x"00"); -- retira 55
        paso('0', '1', x"00"); -- retira 66
        paso('0', '1', x"00"); -- retira 77
        paso('0', '1', x"00"); -- retira 88
        assert (empty = '0' and r_data = x"99")
            report "ERROR: cinco lecturas" severity error;

        -- (i) Ultima lectura: se retira 99; FIFO vacia.
        paso('0', '1', x"00");
        assert (empty = '1' and full = '0')
            report "ERROR: FIFO no marco empty" severity error;

        -- Comprobacion extra: lectura bloqueada por empty.
        paso('0', '1', x"00");
        assert (empty = '1' and full = '0')
            report "ERROR: lectura permitida estando vacia" severity error;

        -- Comprobacion extra de wr=1 y rd=1.
        -- Cuando esta vacia, solo se acepta la escritura AB.
        paso('1', '1', x"AB");
        assert (empty = '0' and r_data = x"AB")
            report "ERROR: operacion simultanea estando vacia" severity error;

        -- Con un dato presente: lee AB y escribe CD.
        paso('1', '1', x"CD");
        assert (empty = '0' and full = '0' and r_data = x"CD")
            report "ERROR: lectura/escritura simultanea" severity error;

        report "SIMULACION TERMINADA: todas las comprobaciones pasaron"
            severity note;
        wait;
    end process;
end architecture sim;
