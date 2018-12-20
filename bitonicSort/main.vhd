library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.types.all;



entity main is
	port (
		clk: in STD_LOGIC;
		rst_n: in STD_LOGIC;
		tx: out STD_LOGIC;
		led: out unsigned(7 downto 0)
	);
end main;

architecture Flow of main is


	constant size: integer := 5;
	constant top: integer := 28;

	component bitonicSort is
		generic(
			logN: integer := 3
		);
		port (
			unsorted: in list(2**logN - 1 downto 0);
			sorted:  out list(2**logN - 1 downto 0)
		);
	end component;
	
	
	
	component serial_tx is
		generic (
			CLK_PER_BIT : integer := 115     -- Needs to be set correctly
		);
		port (
			clk: in  std_logic;
			rst: in std_logic;
 			tx: out std_logic;
			b: in std_logic;
			busy: out std_logic;
			data: in std_logic_vector(7 downto 0);
			new_data: in std_logic
		);
	end component;
	
	signal rst, tick: std_logic;
	signal output: list(2 ** size - 1 downto 0);
	signal input: list(2 ** size - 1 downto 0);
	signal countOut: unsigned(top downto 0) := (others => '0');
	signal t_ready, t_done, t_active: std_logic;
	signal byteOut: unsigned(7 downto 0);
	signal w : std_logic := '1';
begin
	
	rst <= not rst_n;
	
--	led(size downto 0) <= countOut(top downto top - size);
--	led(5 downto size + 1) <= (others => '0');
--	led(6) <= t_ready;
--	led(7) <= t_active;
	
	
	
	
	
	sort: bitonicSort generic map(logN => size)
							   port map(unsorted => input(2 ** size - 1 downto 0), sorted => output);
	
	
	setup: for I in 0 to 2 ** size - 1 generate
		input(I) <= to_unsigned((2 ** size - I) mod 7, 8);
	end generate setup;
	
	
	transmitter: serial_tx generic map (CLK_PER_BIT => 5208)
									port map (clk => clk, rst => '0', tx => tx, b => '0', busy => t_active, data => std_logic_vector(byteOut), new_data => t_ready and w);
	
	

	byteOut <= output(to_integer(countOut(top downto top - size)));
	
	led <= byteOut;
	
	tick <= countOut(top - size - 1);
	process(tick, w, t_active)
	begin
		if t_active = '1' then
			t_ready <= '0';
		elsif tick'EVENT and tick = '1' then
			t_ready <= '1';
		end if;
	end process;
	

	
	count: process (clk, countOut, rst)
	begin
		if rst = '1' then
			countOut <= (others => '0');
			w <= '1';
		elsif countOut(top downto top - size) = to_unsigned(2 ** size - 1, size) then
			w <= '0';
		elsif clk'EVENT and clk = '1' then
			countOut <= countOut + 1;
		end if;
	end process count;
	
	
	
	

end Flow;

