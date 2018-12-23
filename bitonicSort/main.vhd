library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.types.all;



entity main is
	port (
		clk: in STD_LOGIC;
		rst_n: in STD_LOGIC;
		rx: in STD_LOGIC;
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
	
	
	component serial_rx is
		generic (
			CLK_PER_BIT : integer := 115     -- Needs to be set correctly
		);
		port (
			clk: in  std_logic;
			rst: in std_logic;
 			rx: in std_logic;
			data: out std_logic_vector(7 downto 0);
			new_data: out std_logic
		);
	end component;
		
	
	signal rst, tick: std_logic;
	signal output: list(2 ** size - 1 downto 0);
	signal input: list(2 ** size - 1 downto 0);
	signal countOut: unsigned(top downto 0) := (others => '0');
	signal countIn: unsigned(size - 1 downto 0) := (others => '0');
	signal t_ready, t_done, t_active, r_done: std_logic;
	signal byteOut, byteIn: unsigned(7 downto 0);
	signal w : std_logic := '0';
begin
	
	rst <= not rst_n;
	
--	led(size downto 0) <= countOut(top downto top - size);
--	led(5 downto size + 1) <= (others => '0');
--	led(6) <= t_ready;
--	led(7) <= t_active;
	
	
	
	
	
	sort: bitonicSort generic map(logN => size)
							   port map(unsorted => input(2 ** size - 1 downto 0), sorted => output);
	
	
	receiver: serial_rx generic map (CLK_PER_BIT => 5208)
							  port map (clk => clk, rst => rst, rx => rx, unsigned(data) => byteIn, new_data => r_done);
	
	
	transmitter: serial_tx generic map (CLK_PER_BIT => 5208)
								  port map (clk => clk, rst => rst, tx => tx, b => '0', busy => t_active, data => std_logic_vector(byteOut), new_data => t_ready and w);
	
	
	
	byteOut <= output(to_integer(countOut(top downto top - size - 1)));
	
	input(to_integer(countIn)) <= byteIn;
	
	led <= byteOut;
	
	tick <= countOut(top - size - 2);
	process(tick, w, t_active)
	begin
		if t_active = '1' then
			t_ready <= '0';
		elsif tick'EVENT and tick = '1' then
			t_ready <= '1';
		end if;
	end process;
	

	
	count: process (clk, countOut, countIn, r_done, rst)
	begin
		if rst = '1' then
			countOut <= (others => '0');
			countIn <= (others => '0');
			w <= '0';
		else
			case w is
				when '1' =>
					if countOut(top downto top - size - 1) = to_unsigned(2 ** size - 1, size) then
						w <= '0';
						countIn <= (others => '0');
					elsif clk'EVENT and clk = '1' then
						countOut <= countOut + 1;
					end if;
					
				when '0' =>
					if countIn = to_unsigned(2 ** size - 1, size) then
						w <= '1';
						countOut <= (others => '0');
					elsif r_done'EVENT and r_done = '1' then
						countIn <= countIn + 1;
					end if;
				
				when others => report "unreachable" severity failure;
			end case;
		end if;
	end process count;
	
	
	
	

end Flow;

